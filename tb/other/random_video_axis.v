/*
    random_video_axis.v
    Random Video data generator

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
module random_wave_axis_video #(
    parameter DW          = 16,

    parameter ACTIVE_HORI = 1366,
    parameter ACTIVE_VERT = 768
) (
    input  wire aclk,
    input  wire aresetn,

    output reg  signed [DW-1:0] tdata_m,
    output reg                  tlast_m,
    output reg                  tuser_m,
    output reg                  tvalid_m,
    input  wire                 tready_m
);

    // Pixel counter
    reg  [15:0] hori_cnt, vert_cnt;

    // Video output FSM
    localparam STAT_INTV = 2'b00;       // Interval mode
    localparam STAT_TRAN = 2'b01;       // Transfer mode

    reg  [1:0]  stat;
    reg  [15:0] burst_count;
    reg  [15:0] delay_count;
    reg  [15:0] pixels, lines;

    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn) begin
            tdata_m  <= 0;
            tlast_m  <= 1'b0;
            tuser_m  <= 1'b0;
            tvalid_m <= 1'b0;

            burst_count <= 0;
            delay_count <= 0;
            pixels      <= 0;
            lines       <= 0;

            stat <= STAT_TRAN;
        end
        else begin
            case(stat)
            STAT_TRAN:begin
                if(burst_count == 0) begin
                    // Set the count of bytes of the next burst
                    burst_count <= {$random} % 32;
                    // Set interval
                    delay_count <= {$random} % 32;

                    // Switch to interval state to pause transfer
                    stat <= STAT_INTV;
                end
                else begin
                    if(tvalid_m && tready_m) begin
                        tdata_m  <= $random % (2 << DW);
                        tvalid_m <= 1'b1;

                        burst_count <= burst_count - 1;
                        
                        if(pixels == ACTIVE_HORI - 1) begin
                            // The line is ended. line counter + 1
                            if(lines == ACTIVE_VERT - 1)
                                lines <= 0;
                            else
                                lines <= lines + 1;

                            pixels <= 0;
                        end
                        else
                            pixels <= pixels + 1;
                    end
                end
            end
            STAT_INTV:begin
                if(delay_count == 0)
                    stat <= STAT_TRAN;      // Resume transfer
                else
                    delay_count <= delay_count - 1;
            end
            endcase
        end
    end

    always @(*) begin
        case(stat)
        STAT_TRAN:tvalid_m = 1'b1;
        STAT_INTV:tvalid_m = 1'b0;
        endcase

        if(pixels == ACTIVE_HORI - 1)           // End of a line
            tlast_m = 1'b1;
        else
            tlast_m = 1'b0;

        if((lines == 0) && (pixels == 0))       // Start of a frame
            tuser_m = 1'b1;
        else
            tuser_m = 1'b0;
    end
endmodule