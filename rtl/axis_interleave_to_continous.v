/*
    axis_interleave_to_continous.v
    Convert interleaved data stream to continous data stream

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
module axis_interleave_to_continous#(
    parameter DW_IN = 16
) (
    input  wire aresetn,
    input  wire ce,

    // Input slave interface
    input  wire               aclk_s_i,
    input  wire [DW_IN-1:0]   tdata_s_i,
    input  wire [DW_IN/8-1:0] tstrb_s_i,
    input  wire               tid_s_i,
    input  wire               tvalid_s_i,
    output reg                tready_s_o,

    // Output master interface
    input  wire               aclk_m_i,
    output reg  [DW_IN*2-1:0] tdata_m_o,
    output reg  [DW_IN/4-1:0] tstrb_m_o,
    output reg                tvalid_m_o,
    input  wire               tready_m_i
);

    // Upstream clock domain buffers
    reg  [DW_IN-1:0] data_i, data_q;
    reg  tvalid_sample, tready_sample;
    always @(posedge aclk_s_i, negedge aresetn) begin
        if(!aresetn) begin
            data_i <= 0;
            data_q <= 0;

            tvalid_sample <= 1'b0;
            tready_sample <= 1'b0;
        end
        else begin
        if(ce) begin
            if(tvalid_s_i && tready_s_o) begin
                if(tid_s_i)
                    data_i <= 1'b0;
                else
                    data_q <= 1'b0;
            end

            tvalid_sample <= tvalid_s_i;
            // Sync the downstream ready input to upstream clock domain
            tready_sample <= tready_m_i;
        end
        end
    end

    // Downstream clock domain buffers
    always @(posedge aclk_m_i, negedge aresetn) begin
        if(!aresetn) begin
            tdata_m_o  <= 0;
            tvalid_m_o <= 1'b0;
        end
        else begin
        if(ce) begin
            tdata_m_o  <= {data_q, data_i};
            tvalid_m_o <= tvalid_sample;
        end
        end
    end
endmodule