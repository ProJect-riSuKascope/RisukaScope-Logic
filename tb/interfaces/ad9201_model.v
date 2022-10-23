/*
    ad9201_model.v
    Simulation model of AD9201 ADC
    
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
`timescale 1ns/100ps

module ad9201_model(
    input  wire       clock,
    output reg  [9:0] data,
    input  wire       select
);

    // Operation delay
    localparam T_OD = 11;       // Output delay
    localparam T_MD = 7;        // Mux delay

    // Data
    reg [9:0] ch_i_data, ch_q_data;    // Analog value
    reg       ch_last;
    
    initial begin
        ch_i_data = 10'd0;
        ch_q_data = 10'd0;
        ch_last   = 1'b0;
    end

    always @(posedge clock) begin
        ch_i_data <= {$random} % 1024;
        ch_q_data <= {$random} % 1024;

        if(ch_last == select) begin
            if(select)
                #T_OD data = ch_i_data;
            else
                #T_OD data = ch_q_data;
        end
        else begin
            if(select)
                #T_MD data = ch_i_data;
            else
                #T_MD data = ch_q_data;
        end
    end    
endmodule