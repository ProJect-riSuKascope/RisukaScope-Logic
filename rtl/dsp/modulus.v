/*
    modulus.v
    Complex modulus with alpha max and beta min algorithm

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
module modulus #(
    parameter DW = 16
) (
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // Input
    input  wire [DW*2-1:0] tdata_s,
    input  wire            tvalid_s,
    output wire            tready_s,

    // Output
    output reg  [DW-1:0]   tdata_m,
    output reg             tvalid_m,
    input  wire            tready_m
);

    wire signed [DW-1:0]   re = tdata_s[15:0];
    wire signed [DW-1:0]   im = tdata_s[31:16];
    reg  signed [DW-1:0]   abs_re, abs_im;
    reg  signed [17:0]     max, min;            // Margin for 1/64 calculation
    reg  signed [35:0]     modulus;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            abs_re  <= 0;
            abs_im  <= 0;
            max     <= 0;
            min     <= 0;
            modulus <= 0;
        end
        else begin
            if(tvalid_s && tready_s) begin
                abs_re <= (re > 0) ? re : (-re);
                abs_im <= (im > 0) ? im : (-im);
            end

            if(abs_re > abs_im) begin
                max <= abs_re >>> 1;        // 1/64
                min <= abs_im;              // 1/32
            end
            else begin
                max <= abs_im >>> 1;
                min <= abs_re;
            end

            modulus <= max * 61 + min * 13;
        end
    end

    // Output
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            tdata_m  <= 0;
            tvalid_m <= 0;
        end
        else begin
            if(tvalid_m && tready_m)
                tdata_m <= modulus[35:19];

            tvalid_m <= tvalid_s;
        end
    end

    assign tready_s = tready_m;
endmodule