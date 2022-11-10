/*
    graphic_subsystem.v
    Graphic subsystem top module

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
module graphic_subsystem (
    input  wire hclk,
    input  wire hresetn,

    // AHB Interface
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

    output wire [31:0]     hrdata_s,
    output wire            hreadyout_s,
    output wire            hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire            hsel_s,

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

    // Parameters
    localparam MIF_INST    = "inst.mem";
    localparam MIF_PALETTE = "palette.mem";
    localparam MIF_STRING  = "string.mem";
    localparam MIF_CHART   = "chart.mem";

    // PLL for Video pixel
    wire clk_serial;
    wire clk_pixel;

    pll_pixel clk_video_gen(
        .clkin (hclk),
        .clkout(clk_pixel)
    );

    /*
    clk_div_pixel clk_div(
        .clkout(clk_pixel), //output clkout
        .hclkin(clk_serial), //input hclkin
        .resetn(hresetn) //input resetn
    );
    */

    // Video generator
    wire  [15:0] tdata_video;
    wire         tlast_video;
    wire         tuser_video;
    wire         tvalid_video;
    wire         tready_video;

    graphic_generator #(
        .MIF_INST("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/rtl/graphic/graph_inst_compiler/inst.mem"),
        .MIF_STRING("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/rtl/graphic/graph_inst_compiler/data.mem"),
        .MIF_CHART("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/rtl/graphic/graph_inst_compiler/chart.mem"),
        .MIF_PALETTE("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/data/palette.mem")
    ) gen_0(
      .hclk    (clk_pixel ),
      .hresetn (hresetn ),
      .ce      (1'b1),

      .haddr_s     (haddr_s ),
      .hburst_s    (hburst_s ),
      .hsize_s     (hsize_s ),
      .htrans_s    (htrans_s ),
      .hwdata_s    (hwdata_s ),
      .hwrite_s    (hwrite_s ),
      .hrdata_s    (hrdata_s ),
      .hreadyout_s (hreadyout_s ),
      .hresp_s     (hresp_s ),
      .hsel_s      (hsel_s ),

      .tdata_m   (tdata_video ),
      .tlast_m   (tlast_video ),
      .tuser_m   (tuser_video ),
      .tvalid_m  (tvalid_video ),
      .tready_m  (tready_video )
    );

    // Stream to video out
    stream_2_video_out vout (
      .clk     (clk_pixel ),
      .reset_n (hresetn ),

      .tdata_s  (tdata_video ),
      .tlast_s  (tlast_video ),
      .tuser_s  (tuser_video ),
      .tvalid_s (tvalid_video ),
      .tready_s (tready_video ),

      .video_r      (vout_r),
      .video_b      (vout_b),
      .video_g      (vout_g),
      .hsync        (vout_hsync ),
      .vsync        (vout_vsync ),
      .hblank       ( ),
      .vblank       ( ),
      .active_video (vout_active)
    );

    // HDMI output
    hdmi_tx hdmi_tx_0(
		.I_rst_n   (hresetn), //input I_rst_n
		.I_rgb_clk (clk_pixel), //input I_rgb_clk

        .I_rgb_r  ({vout_r, 3'd0}), //input [7:0] I_rgb_r
		.I_rgb_g  ({vout_g, 3'd0}), //input [7:0] I_rgb_g
		.I_rgb_b  ({vout_b, 3'd0}), //input [7:0] I_rgb_b
//        .I_rgb_r  (vout_r), //input [7:0] I_rgb_r
//		.I_rgb_g  (vout_g), //input [7:0] I_rgb_g
//		.I_rgb_b  (vout_b), //input [7:0] I_rgb_b
		.I_rgb_vs (vout_vsync), //input I_rgb_vs
		.I_rgb_hs (vout_hsync), //input I_rgb_hs
		.I_rgb_de (vout_active), //input I_rgb_de

		.O_tmds_clk_p  (tmds_clk_p), //output O_tmds_clk_p
		.O_tmds_clk_n  (tmds_clk_n), //output O_tmds_clk_n
		.O_tmds_data_p (tmds_data_p), //output [2:0] O_tmds_data_p
		.O_tmds_data_n (tmds_data_n) //output [2:0] O_tmds_data_n
	);

endmodule