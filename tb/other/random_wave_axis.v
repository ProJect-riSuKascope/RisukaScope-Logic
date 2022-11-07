/*
    random_wave_axis.v
    Random Continous Wave Generator with AXI-Stream Interface

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
module random_wave_axis #(
    parameter DW        = 16,
    parameter PHASE_INC = 0.01 
) (
    input  wire aclk,
    input  wire aresetn,

    output reg  signed [DW-1:0] tdata_m_o,
    output reg                  tvalid_m_o,
    input  wire                 tready_m_i
);

    localparam PI = 3.14359265;

    integer data, cnt;
    real factor, phase, value;

    reg  prev_sign;
    reg  zero_crossed;      // Flag indicating there's a zero-crossing in a cycle

    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn) begin
            tdata_m_o  <= 0;
            tvalid_m_o <= 1'b1;

            cnt    <= 0;
            prev_sign    <= 1'b0;
            zero_crossed <= 1'b0;

            value  <= 0;
            factor <= 0.5;
            data   <= 0;
        end
        else begin
            phase     <= PI * PHASE_INC * cnt;
            value     <= $sin(phase) * 0.706;           // sqrt(2)
            data      <= $rtoi(factor * value * (1 << (DW-1)) );
            tdata_m_o <= data;

            // Update the factor if the value is crossing zero
            if(prev_sign != (data > 0) ) begin
                // Cross-zero
                if(zero_crossed) begin
                    factor <= $itor({$random} % (2 ** 16)) / $itor(2 ** 16);
                    zero_crossed <= 1'b0;
                end
                else
                    zero_crossed <= 1'b1;

                prev_sign    <= (data > 0);
            end

            cnt <= cnt + 1;
        end
    end
endmodule