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
    input  wire [DW-1:0] tdata_s,
    input  wire          tvalid_s,
    output reg           tready_s,

    output reg  [DW-1:0] tdata_m,
    output reg           tvalid_m,
    input  wire          tready_m,

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
    output reg             hresp_s
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.
);

    // Interface signals
    reg [31:0] haddr_last;

    // Registers
    reg  [31:0] reg_ctrl;

    reg                coeff_r;
    reg                coeff_we;
    reg  signed [15:0] rd_coeff;

    reg  [15:0] coeffs  [0:1023];
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n)
            coeff_r <= 0;
        else begin
            if(coeff_we)
                coeffs[haddr_last[9:1]] <= hwdata_s[15:0];

            rd_coeff <= coeffs[rd_ptr];
        end
    end

    // Fields
    wire        enable = reg_ctrl[0];
    wire [15:0] rate   = reg_ctrl[31:16];

    // FIR Filter
    reg  [9:0] wr_ptr, rd_ptr;
    reg  [9:0] cycle;

    reg         [15:0] buffer[0:1023];
    reg  signed [15:0] rd_data;     // Buffer read data
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
                if(wr_ptr == rate - 1)
                    wr_ptr <= 10'h0;
                else
                    wr_ptr <= wr_ptr + 1;

                rd_ptr <= wr_ptr + 1;
            end
            else begin
                if(rd_ptr == rate - 1)
                    rd_ptr <= 10'h0;
                else
                    rd_ptr <= rd_ptr + 1;
            end

            // Read data from buffer
            rd_data  <= buffer[rd_ptr];

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
                    tdata_m  <= acc[31:16];             // Q15
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

    `include "ahb_intf_fir.v"
endmodule