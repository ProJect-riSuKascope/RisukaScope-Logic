/*
    axi_stream_sink.v
    AXI-Stream Data Sink
    
    Copyright 2022 Hiryuu T., Lyskamm Manufacturing

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
module axi_stream_sink #(
    parameter TDATA_WIDTH = 16,
    parameter TID_WIDTH   = 1,
    parameter TDEST_WIDTH = 1,
    parameter TUSER_WIDTH = 1,

    parameter USE_TKEEP = 0,
    parameter USE_TLAST = 0,
    parameter USE_TID = 0,
    parameter USE_TDEST = 0,
    parameter USE_TUSER = 0,
    parameter USE_TWAKEUP = 0
)(
    // Clock and reset
    input  wire aclk,
    input  wire aresetn,

    // AXI-Stream signals
    input  wire [TDATA_WIDTH - 1:0] tdata_s_in,
    input  wire [TDATA_WIDTH / 8:0] tstrb_s_in,
    input  wire [TDATA_WIDTH / 8:0] tkeep_s_in,
    input  wire                     tlast_s_in,
    input  wire [TID_WIDTH - 1:0]   tid_s_in,
    input  wire [TDEST_WIDTH - 1:0] tdest_s_in,
    input  wire [TUSER_WIDTH - 1:0] tuser_s_in,
    input  wire                     twakeup_s_in,

    input  wire                     tvalid_s_in,
    output reg                      tready_s_out
);

    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn)
            tready_s_out <= 1;
        else begin
            tready_s_out <= {$random} % 2;

            if(tvalid_s_in && tready_s_out) begin
                $display("Transaction at %t:", $time);
                $display("TDATA=%8X, TSTRB=%1X", tdata_s_in, tstrb_s_in);

                if(USE_TKEEP)
                    $display("TKEEP=%1X", tkeep_s_in);
                if(USE_TLAST)
                    $display("TLAST=%d", tlast_s_in);
                if(USE_TID)
                    $display("TID=%8X", tid_s_in);
                if(USE_TDEST)
                    $display("TDEST=%8X", tdest_s_in);
                if(USE_TUSER)
                    $display("TUSER=%8X", tuser_s_in);
                if(USE_TWAKEUP)
                    $display("TWAKEUP=%1X", twakeup_s_in);
            end
        end
    end
endmodule