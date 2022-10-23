/*
    fir_section_symmetry_mc_bram.v
    Symmetry FIR section for coefficient symmetry (standard high-pass and low-pass) filters
    (Coefficient modifiable)

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

module fir_section_mc_bram #(
    parameter DW = 16,
    parameter OUT_DW = 32,
    parameter NUMW = 18,        // Coefficient numerator width

    parameter LGN = 3
) (
    input  wire clk_sample,
    input  wire reset_n,
    input  wire ce,

    /* Status output */
    input  wire [15:0] cycle,
    input  wire [15:0] total_cycles,

    /* Samples */
    input  wire [DW-1:0] f_prev,
    output reg  [DW-1:0] f_next,

    input  wire [DW-1:0] b_next,
    output reg  [DW-1:0] b_prev,

    output reg  signed [OUT_DW:0] result,

    /* Coefficient modify */
    input  wire signed [DW-1:0] coeff
);

    // Store sample data with an RAM-based shift register.
    // samples_f and samples_b will be synthesized to shift register.
    reg  signed [DW-1:0] samples_f [0:31];
    reg  signed [DW-1:0] samples_b [0:31];
    reg         [15:0]   wr_ptr;
    wire sreg_wr;

    always @(posedge clk_sample, negedge reset_n) begin
        if(!reset_n)
            wr_ptr <= 16'd0; 
        else begin
        if(ce) begin
            if(sreg_wr) begin
                // Shift in
                samples_f[wr_ptr] <= f_prev;
                samples_b[wr_ptr] <= b_next;

                // Shift out
                f_next <= samples_f[wr_ptr];
                b_prev <= samples_b[wr_ptr];

                // Write pointer increace
                wr_ptr <= wr_ptr + 1;
            end
        end
        end
    end
 
    // Shift register control
    wire [15:0] rd_ptr_f, rd_ptr_b;
    assign rd_ptr_f = cycle;
    assign rd_ptr_b = total_cycles - cycle;

    assign sreg_wr  = (cycle == 0);

    // Calculation
    wire signed [DW:0] sample_sum;
    assign sample_sum = curr_f + curr_b;
    wire signed [OUT_DW-1:0] prod;
    assign prod = coeff * sample_sum;

    reg  signed [OUT_DW-1:0] sum;
    reg  signed [DW-1:0] curr_f, curr_b;

    always @(posedge clk_sample, negedge reset_n) begin
        if(!reset_n) begin
            result <= {OUT_DW{1'b0}};
            sum    <= {OUT_DW{1'b0}};
            
            curr_f <= {DW{1'b0}};
            curr_b <= {DW{1'b0}};
        end
        else begin
        if(ce) begin
            if(cycle == 2) begin
                sum    <= prod;
                result <= (sum >>> NUMW);
            end
            else
                sum <= sum + prod;

            curr_f <= samples_f[rd_ptr_f];
            curr_b <= samples_b[rd_ptr_b];
        end
        end
    end
endmodule