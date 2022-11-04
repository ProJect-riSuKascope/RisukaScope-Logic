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
    output reg           tready_s,

    // Output AXI-Stream
    output reg  [DW-1:0] tdata_m,
    output reg           tvalid_m,
    output reg           tlast_m,
    input  wire          tready_m,

    // External sync
    input  wire          ext_sync
);
    
    reg  [15:0]   cnt;
    reg  [DW-1:0] tdata_last;
    reg           tvalid_last;
    reg  [DW-1:0] tdata_mp;
    reg           tvalid_mp;

    reg           stat;

    localparam STAT_TRAN = 1'b0;
    localparam STAT_HALT = 1'b1;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            cnt        <= 0;
            stat       <= STAT_TRAN;

            tdata_mp    <= 0;
            tdata_last  <= 1'b0;
            tvalid_mp   <= 0;
            tvalid_last <= 1'b0;

            tready_s    <= 1'b1;
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
                end
            end

            case(stat)
            STAT_TRAN:begin
                if(tvalid_s && tready_s) begin
                    tvalid_m    <= tvalid_s;
                    tdata_m     <= tdata_s;
                end

                if(tready_m) begin
                    tdata_last  <= tdata_s;
                    tvalid_last <= tvalid_s;
                end
                else
                    stat <= STAT_HALT;
            end
            STAT_HALT:begin
                if(tready_m)
                    stat <= STAT_HALT;
            end
            endcase

            // tready pipeline
            tready_s <= tready_m;
        end
    end

    always @(*) begin
        tlast_m = (cnt == FRAME_LEN - 1);

        case(stat)
            STAT_TRAN:begin
                tdata_m  = tdata_mp;
                tvalid_m = tvalid_mp;
            end
            STAT_HALT:begin
                tdata_m  = tdata_last;
                tvalid_m = tvalid_last;
            end
        endcase
    end
endmodule