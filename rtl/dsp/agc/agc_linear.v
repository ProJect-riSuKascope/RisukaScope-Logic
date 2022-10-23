/*
    agc_linear.v
    Linear AGC

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
module agc_linear#(
    parameter               DW = 16,
    parameter signed [15:0] K  = 10
)(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // Data input
    input  wire [DW-1:0] tdata_s,
    input  wire          tvalid_s,
    output wire          tready_s,

    // AGC output
    output reg  [DW-1:0] tdata_m,
    output reg           tvalid_m,
    input  wire          tready_m,

    // AHB Interface
    // HCLK, HRESETn are combined into global signals.
    input  wire [31:0]     haddr_s,
    input  wire [2:0]      hburst_s,
    // Locked sequence (HMASTLOCK) is not used.
    // Protection option (HPROT[6:0]) is not used.
    input  wire [2:0]      hsize_s,
    // Secure transfer (HNONSEC) is not used.
    // Exclusive transfer (HEXCL) is not used.
    // Master identifier (HMASTER[3:0]) is not used.
    input  wire [1:0]      htrans_s,
    input  wire [31:0]     hwdata_s,
    input  wire            hwrite_s,

    output reg  [31:0]     hrdata_s,
    output reg             hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire            hsel_s
);

    // Registers
    reg  [31:0] reg_ctrl;
    reg  [31:0] reg_gain_read;
    reg  [31:0] reg_gain_ctrl;
    reg  [31:0] reg_value_read;
    reg  [31:0] reg_value_ctrl;
    reg  [15:0] reg_hystersis;
    reg  [15:0] reg_step;

    // Fields for gain calculation
    wire signed [DW-1:0]   gain_inc_max = reg_gain_ctrl[31:16];
    wire signed [DW-1:0]   step = reg_step[15:0];
    wire signed [DW-1:0]   desire = reg_value_ctrl[15:0];
    wire signed [DW-1:0]   overflow_margin = reg_value_ctrl[31:16];
    wire signed [DW-1:0]   hystersis = reg_hystersis[15:0];

    // AXI-Stream interface
    reg  signed [DW-1:0] data;
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            data <= 0;
        end 
        else begin
            if(tvalid_s && tready_s)
                data <= (tdata_s > 0) ? tdata_s : (-tdata_s);
        end   
    end

    assign tready_s = 1'b1;

    // Smooth module
    wire signed [DW-1:0] smoothed;

    average #(
      .DW(DW),
      .K (K)
    )average_0 (
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce && tvalid_s && tready_s),

      .din  (tdata_s),
      .dout (/* N/A */),
      .mean (smoothed)
    );

    // Calculate gain
    reg  signed [DW-1:0]   gain;
    reg  signed [DW*2-1:0] gain_inc_0;
    wire signed [DW-1:0]   gain_inc = gain_inc_0[DW*2-1:DW];
    wire signed [DW-1:0]   error = desire - smoothed;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            gain_inc_0 <= 0;
            gain       <= 0;
        end
        else begin
        if(ce) begin
            gain_inc_0 <= error * step;

            if(smoothed < overflow_margin) begin
                // Set the normal gain if the value would not overflow
                if(gain_inc > hystersis || (gain_inc < -hystersis)) begin
                    // If the increacement is larger than hystersis
                    // Gain increacement clipping
                    if(gain_inc > gain_inc_max)
                        gain <= gain + gain_inc_max;
                    else if(gain_inc < (-gain_inc_max))
                        gain <= gain - gain_inc_max;
                    else
                        gain <= gain + gain_inc;
                end
            end
            else begin
                // Decrace the gain if it would make the gained value overflow
                gain <= -gain;
            end
        end
        end
    end

    // Output
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            tdata_m  <= 0;
            tvalid_m <= 1'b0;
        end
        else begin
        if(ce) begin
            if(tvalid_m && tready_m)
                tdata_m <= gain;

            // Update gain at next sampling
            tvalid_m <= tvalid_s && tready_s;
        end
        end
    end

`include "agc_ahb_intf.v"
endmodule
