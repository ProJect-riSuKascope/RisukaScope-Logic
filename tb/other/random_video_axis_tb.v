/*
    random_wave_axis_video_tb.v
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
`timescale 1ns/100ps

module random_wave_axis_video_tb();
    localparam PERIOD_ACLK = 10;
    // Signals
    reg aclk, aresetn;

    wire [15:0] tdata_m;
    wire        tlast_m;
    wire        tuser_m;
    wire        tvalid_m;
    wire        tready_m;

    random_wave_axis_video #(
      .DW(16),
      .ACTIVE_HORI(640),
      .ACTIVE_VERT(480)
    ) dut(
      .aclk (aclk ),
      .aresetn (aresetn ),

      .tdata_m (tdata_m ),
      .tlast_m (tlast_m ),
      .tuser_m (tuser_m ),
      .tvalid_m (tvalid_m ),
      .tready_m  ( tready_m)
    );

    // Other modules
    assign tready_m = 1'b1;

    // Testbench process
    initial begin
        aclk = 1'b0;

        aresetn = 1'b0;
        repeat(10) @(posedge aclk);
        aresetn = 1'b1;
    end

    always #(PERIOD_ACLK/2) aclk = ~aclk;

    always begin
        repeat(100000) @(posedge aclk);
        $stop();
    end
endmodule