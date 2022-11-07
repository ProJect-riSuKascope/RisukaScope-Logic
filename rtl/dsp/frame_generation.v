/*
    frame_generation.v
    Identify continous data stream to frames w/ AXI-Stream sync bridge

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
module frame_generation #(
    parameter DW        = 16,
    parameter FRAME_LEN = 1024
)(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // Input AXI-Stream
    input  wire [DW-1:0] tdata_s,
    input  wire          tvalid_s,
    output wire          tready_s,

    // Output AXI-Stream
    output reg  [DW-1:0] tdata_m,
    output reg           tvalid_m,
    output wire          tlast_m,
    output wire          tuser_m,
    input  wire          tready_m,

    // External sync
    input  wire          ext_sync
);
    
    reg  [15:0]   cnt;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            cnt        <= 0;

            tdata_m    <= 0;
            tvalid_m   <= 1'b0;
        end
        else begin
            if(ext_sync)
                cnt <= 0;
            else begin
                if(tvalid_s && tready_s) begin
                    if(cnt == FRAME_LEN - 1)
                        cnt <= 0;
                    else
                        cnt <= cnt + 1;

                    tdata_m <= tdata_s;
                end

                tvalid_m <= tvalid_s;
            end
        end
    end

    assign tlast_m  = (cnt == FRAME_LEN - 1);
    assign tuser_m  = (cnt == 0);
    assign tready_s = tready_m;
endmodule