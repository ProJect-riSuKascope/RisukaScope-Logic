/*
    fir_bram_mc.v
    Multi-cycle FIR wilter w/ BRAM
    (Coefficient modifiable)

    Copyright 2021-2022 Hiryuu T. (PFMRLIB)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
module fir_bram_mc #(
    parameter DW = 16,

    // AHB Bus address
    parameter BUS_ADDR    = 32'h0000_0001,
    parameter BUS_PERI_AW = 8
) (
    // Global clock and reset
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // AXI-Stream interface
    input  wire [2*DW-1:0] tdata_s,
    input  wire            tvalid_s,
    output reg             tready_s,

    output reg  [2*DW-1:0] tdata_m,
    output reg             tvalid_m,
    input  wire            tready_m,

    // AHB Control Interface
    // HCLK, HRESETn are combined into global signals.
    input  wire [31:0]     haddr_s,
    input  wire [2:0]      hburst_s,
    // Locked sequence (HMASTLOCK) is not used.
    // Protection option (HPROT[6:0]) is not used.
    input  wire [2:0]      hsize_s,
    // Secure transfer (HNONSEC) is not used.
    // Exclusive transfer (HEXCL) is not used.
    // Master identifier (HMASTER[3:0]) is not used.
    input  wire [1:0]      htrans_s,
    input  wire [31:0]     hwdata_s,
    input  wire            hwrite_s,

    output reg  [31:0]     hrdata_s,
    output reg  [31:0]     hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    // Output fields
    output wire [15:0] rate,
    output wire        enable
);

    // Register interface
    // AHB FSM
    localparam AHB_IDLE = 2'b00;
    localparam AHB_NONSEQ = 2'b10;
    localparam AHB_BUSY = 2'b01;
    localparam AHB_SEQ = 2'b11;

    // FSM state signals
    reg  [1:0]  stat;
    reg         wr;

    // Register access signals
    reg  [3:0]  wstrb;       // Strobe signal

    // Address and strobe decoder
    always @(*) begin
        case(hsize_s)
        3'b000:begin
            // Byte (8b)
            case(haddr_s[1:0])
                2'b00:wstrb = 4'b0001;
                2'b01:wstrb = 4'b0010;
                2'b10:wstrb = 4'b0100;
                2'b11:wstrb = 4'b1000;
                default:wstrb = 4'b0000;
            endcase
            end
        3'b001:begin
            // Halfword (16b)
            case(haddr_s[1:0])
                2'b00:wstrb = 4'b0011;
                2'b10:wstrb = 4'b1100;
                default:wstrb = 4'b0000;
            endcase
        end
        3'b010:wstrb = 4'b1111;
        default:wstrb = 4'b0000;
        endcase
    end

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            stat <= 2'b00;
            wr   <= 1'b0;
        end
        else begin
        if(ce) begin
            case(htrans_s)
            AHB_NONSEQ, AHB_SEQ:begin
                if(hwrite_s)
                    write(haddr_s, hwdata_s, wstrb);
                else
                    read(haddr_s, hrdata_s);
            end
            endcase
        end
        end
    end

    // Define registers
    reg  [31:0] reg_ctrl;
    reg  [31:0] coeffs[0:511];

    // Read/Write
    task write( 
        input  [15:0] addr,
        input  [31:0] data,
        input  [3:0]  strb
    );
    begin
        casex(addr)
            16'h0000:reg_ctrl <= data;
            16'h1xxx:coeffs[addr[10:2]] <= data;
        endcase
    end
    endtask

    task read(
        input  [15:0] addr,
        output [31:0] data
    );
    begin
        case(addr)
            16'h000:data <= reg_ctrl;
        endcase
    end
    endtask

    // Fields
    assign enable = reg_ctrl[0];
    assign rate   = reg_ctrl[31:16];

    // FIR Filter
    reg  [9:0] wr_ptr, rd_ptr;
    reg  [9:0] cycle;

    reg         [15:0] buffer[0:1023];
    reg  signed [15:0] rd_data;     // Buffer read data
    reg  signed [15:0] rd_coeff;    // Coefficient read data
    reg  signed [31:0] acc;         // Accumulator

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            wr_ptr <= 10'h0;
            rd_ptr <= 10'h0;

            cycle  <= 10'h0;
        end
        else begin
        if(ce && enable && tready_s) begin
            if (rd_ptr == wr_ptr - 1) begin
                if(wr_ptr == rate)
                    wr_ptr <= 10'h0;
                else
                    wr_ptr <= wr_ptr + 1;

                rd_ptr <= wr_ptr + 1;
            end
            else begin
                if(rd_ptr == rate)
                    rd_ptr <= 10'h0;
                else
                    rd_ptr <= rd_ptr + 1;
            end

            // Read coeff from coeff RAM
            if(rd_ptr[0])
                rd_coeff <= coeffs[rd_ptr[9:1]][15:0];      // Use low 16bits of coefficient at even pointers
            else
                rd_coeff <= coeffs[rd_ptr[9:1]][31:16];     // Use low 16bits of coefficient at odd pointers

            // Read data from buffer
            rd_data <= buffer[rd_ptr];

            // Calculate and accumulate
            if(rd_ptr == wr_ptr)
                acc <= 0;
            else
                acc <= rd_data * rd_coeff + acc;
        end
        end
    end

    // Stream I/O
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            tdata_m  <= 0;
            tvalid_m <= 1'b0;
        end
        else begin
        if(ce) begin
            // Check if the decimator is enabled
            if(enable) begin
                // Output if read pointer equals to write pointer.
                if(rd_ptr == wr_ptr) begin
                    tdata_m  <= acc;
                    tvalid_m <= 1'b1;
                end
                else
                    tvalid_m <= 1'b0;
                end
            else begin
                // Bypass the filter if not used
                tdata_m  <= tdata_s;
                tvalid_m <= tvalid_s;
            end

            tready_s <= tready_m;
        end
        end
    end
endmodule