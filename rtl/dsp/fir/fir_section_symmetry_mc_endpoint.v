/*
    fir_section_symmetry_mc_endpoint.v
    Ednpoint module of symmetry FIR sections
    (Coefficient modifiable)

    Copyright 2021 Hiryuu T. (PFMRLIB)

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

module fir_section_symmetry_mc_endpoint #(
    parameter DW  = 16,
    parameter NUMW = 18,        // Coefficient numerator width

    parameter N   = 8,
    parameter LGN = 3
) (
    input  wire clk_sample,
    input  wire reset_n,
    input  wire ce,

    /* Status output */
    input  wire [LGN-1:0] cycle,

    /* Samples */
    input  wire signed [DW-1:0] f_prev,
    output reg  signed [DW-1:0] b_prev,

    output reg         [DW-1:0] result,

    /* Coefficient modify */
    input  wire signed [DW-1:0] coeff
);

    /* Samples */
    wire signed [DW:0]   sum;
    assign sum  = f_prev + b_prev;
    wire signed [DW*2:0] prod;
    assign prod = coeff * sum;
    
    always @(posedge clk_sample, negedge reset_n) begin
        if(!reset_n) begin
            b_prev  <= {DW{1'b0}};
            result  <= {DW{1'b0}};
        end
        else begin
        if(ce) begin
            if(cycle == N-1)
                b_prev <= f_prev;

            if(NUMW>DW)
                result <= { {(NUMW-DW){prod[DW*2]}}, prod[DW*2:NUMW]};
            else
                result <= prod[(NUMW+DW):NUMW];
        end
        end
    end
endmodule