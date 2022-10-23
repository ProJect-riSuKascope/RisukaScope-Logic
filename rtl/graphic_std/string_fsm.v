/*
    stream_buffer_tb_registers.v
    Testbench of AHB interface in Stream buffer

    Copyright 2022 Hiryuu T. (PFMRLIB)

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
module string_fsm#(
    parameter FONT_FILE = ""
)(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // String access
    output wire [31:0] str_addr,
    input  wire [31:0] str_addr_base,
    input  wire [7:0]  str_data,
    
    // Frame buffer write
    output wire [31:0] pixel_data,
    output wire [31:0] pixel_addr,
    output wire        pixel_write,

    // AHB Interface
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
    output reg             hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire            hsel_s
);

    // Font ROM
    reg  [31:0] font[0:511];
    initial begin
        $readmemh(FONT_FILE);
    end
    // 

    // Registers
    // Register mapping for AHB Interface
    task reg_read_ahb(
        input  [15:0] addr,
        output [31:0] data
    );
    begin

    end
    endtask

    task reg_write_ahb(
        input  [15:0] addr,
        input  [31:0] data
    );
    begin
        // Empty write.
    end
    endtask
    // AHB FSM
    reg  [31:0] haddr_last;
    reg         hwrite_last;
    reg  [31:0] hwdata_last;

    // AHB FSM
    localparam  AHB_IDLE  = 2'b00;
    localparam  AHB_READ  = 2'b01;
    localparam  AHB_WRITE = 2'b10;
    localparam  AHB_ERROR = 2'b11;

    reg  [1:0]  ahb_stat;

    task ahb_transcation();
    begin
        if(hwrite_s) begin
            // Record data and address for write access
            haddr_last  <= haddr_s;
            hwrite_last <= hwrite_s;
            hwdata_last <= hwdata_s;

            ahb_stat <= AHB_WRITE;
        end
        else begin
            // Fetch data from read buffer
            reg_read_ahb(haddr_s, hrdata_s);
            ahb_stat <= AHB_READ;
        end
    end
    endtask

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            haddr_last  <= 0;
            hwdata_last <= 0;
            hwrite_last <= 1'b0;

            hrdata_s    <= 'h0;

            ahb_stat <= AHB_IDLE;
        end
        else begin
        if(ce) begin
            case(ahb_stat)
                AHB_IDLE, AHB_READ:begin
                    // Nothing to do
                    if(hsel_s) begin
                        ahb_transcation();
                    end
                    else begin
                        ahb_stat <= AHB_IDLE;
                    end
                end
                AHB_WRITE:begin
                    ahb_stat <= AHB_ERROR;
                end
                AHB_ERROR:begin
                    ahb_stat <= AHB_IDLE;
                end
            endcase
        end
    end
    end

    always @(*) begin
        case(ahb_stat)
            AHB_IDLE, AHB_READ:begin
                hreadyout_s = 1'b1;
                hresp_s     = 1'b0;
            end
            AHB_WRITE:begin
                // Write to register
                // The stream buffer is not available to write, so an error signal is generated
                // Error stage 1
                hresp_s     = 1'b1;
                hreadyout_s = 1'b0;
            end
            AHB_ERROR:begin
                // Error stage 1
                hresp_s     = 1'b1;
                hreadyout_s = 1'b0;
            end
            default:begin
                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;
            end
        endcase
    end
endmodule