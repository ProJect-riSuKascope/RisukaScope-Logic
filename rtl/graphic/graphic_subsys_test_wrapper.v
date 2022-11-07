/*
    graphic_subsystem.v
    Graphic subsystem wrapper

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
module graphic_subsys_test_wrapper (
    input  wire clk_sys,
    input  wire reset_n,

    // Graphic out interface
    output wire [4:0]      vout_r,
    output wire [4:0]      vout_g,
    output wire [5:0]      vout_b,
    output wire            vout_hsync,
    output wire            vout_vsync,
    output wire            vout_active,
    
    // HDMI Tx
    output wire            tmds_clk_p,
    output wire            tmds_clk_n,
    output wire [2:0]      tmds_data_p,
    output wire [2:0]      tmds_data_n
);

    // System PLL
    wire hclk = clk_sys;
    /*
    pll_sys sys_pll(
        .clkin (clk_sys),
        .clkout(hclk)
    );
    */

    graphic_subsystem dut (
        .hclk    (clk_sys ),
        .hresetn (reset_n ),

        .haddr_s  (0 ),
        .hburst_s (3'b000 ),
        .hsize_s  (3'b000 ),
        .htrans_s (2'b00 ),
        .hwdata_s (0 ),
        .hwrite_s (1'b0 ),

        .hrdata_s    ( ),
        .hreadyout_s ( ),
        .hresp_s     ( ),

        .hsel_s (1'b0 ),

        .vout_r      (vout_r ),
        .vout_g      (vout_g ),
        .vout_b      (vout_b ),
        .vout_hsync  (vout_hsync ),
        .vout_vsync  (vout_vsync ),
        .vout_active (vout_active ),

        .tmds_clk_p  (tmds_clk_p ),
        .tmds_clk_n  (tmds_clk_n ),
        .tmds_data_p (tmds_data_p ),
        .tmds_data_n (tmds_data_n )
    );
endmodule