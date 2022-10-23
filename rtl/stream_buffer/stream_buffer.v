/*
    stream_buffer.v
    Buffer, stream input with addressable interface

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
module stream_buffer(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // AXI-Stream input
    input  wire [15:0] tdata_s,
    input  wire        tlast_s,         
    input  wire        tuser_s,         // Used as frame start identifier
    input  wire        tvalid_s,
    output wire        tready_s,

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

    // Buffer
    reg  [15:0] buffer [0:1023];

    // Buffer write
    reg  [9:0]  idx;

    localparam STAT_IDLE  = 1'b0;
    localparam STAT_WRITE = 1'b1;
    reg  [1:0]  stat;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            stat <= STAT_IDLE;
            idx  <= 'd0;
        end
        else begin
        if(ce) begin
            case(stat)
            STAT_IDLE:begin
                if(tuser_s) begin
                    stat <= STAT_WRITE;
                    idx  <= 'h0;
                end
            end
            STAT_WRITE:begin
                if(tvalid_s && tready_s) begin
                    buffer[idx] <= tdata_s;
                    idx         <= idx + 1;

                    if(tlast_s)
                        stat <= STAT_IDLE;
                end
            end
            endcase
        end
        end
    end

    assign tready_s = (stat == STAT_WRITE);

    // AHB Interface
    `include "ahb_intf_streambuffer.v"
endmodule