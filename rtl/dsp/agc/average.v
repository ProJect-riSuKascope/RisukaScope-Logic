/*
    average.v
    Simple high-pass filter / Average signal calculation

    Ref:Ken Chapman. "Digitally Removing DC Offset: DSP Without Mathematics". White Paper: Xilinx FPGAs(2008):WP279.

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

module average#(
    parameter               DW  = 16,
    parameter signed [15:0] K   = 10
)(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    input  wire signed [DW-1:0] din,

    output wire        [DW-1:0] dout,
    output wire signed [DW-1:0] mean
);

    /* The digital RC circuit */
    reg  signed [DW-1:0]   err;
    reg  signed [2*DW-1:0] acc;
    wire signed [2*DW-1:0] prod;
    assign prod = err <<< K;
    //wire signed [DW-1:0]   mean;
    assign mean = acc[DW*2-1:DW];

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            err   <= {DW{1'b0}};
            acc   <= {(2*DW){1'b0}};
        end
        else begin
        if(ce) begin
            err <= din - mean;
            acc <= prod + acc;
        end
        end
    end

    // As you can see, the err value is equal to the output(DC removed) value.
    assign dout = err;
endmodule