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

    output reg  [31:0]     hrdata_s,
    output reg             hreadyout_s,
    output reg             hresp_s,
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
    output wire [2:0]      tmds_data_n,

    // DDR3 MIF
    // DDR3 memory interface
    output wire [13:0]     ddr_addr_o,
    output wire [2:0]      ddr_ba_o,
    output wire            ddr_cs_n_o,
    output wire            ddr_ras_n_o,
    output wire            ddr_cas_n_o,
    output wire            ddr_we_n_o,
    output wire            ddr_clk_o,
    output wire            ddr_clk_n_o,
    output wire            ddr_cke_o,
    output wire            ddr_odt_o,
    output wire            ddr_reset_n_o,
    output wire [1:0]      ddr_dqm_o,
    inout  wire [15:0]     ddr_dq_io,
    inout  wire [1:0]      ddr_dqs_io,
    inout  wire [1:0]      ddr_dqs_n_io
);

    // Parameters
    localparam INST_BUFFER_MIF = "test.mem";

    // Video generator
    wire  [15:0] tdata_video;
    wire         tlast_video;
    wire         tuser_video;
    wire         tvalid_video;
    wire         tready_video;

    graphic_generator #(
      .INST_BUFFER_MIF (INST_BUFFER_MIF )
    ) gen_0(
      .hclk    (hclk ),
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
  
    
    // PLL for DDR3 Memory
    wire clk_ddr;
    wire clk_ddr_lock;

    pll_ddr3 clk_ddr_gen(
        .clkin (hclk),

        .clkout(clk_ddr),
        .lock  (clk_ddr_lock)
    );

    // PLL for Video pixel
    wire clk_pixel;

    pll_video clk_video_gen(
        .clkin (hclk),
        .clkout(clk_pixel)
    );

    // Internal clock for video components
    wire clk_internal;

    // DDR3 Memory interface
    wire [2:0]   mem_cmd;
    wire         mem_cmd_valid;
    wire         mem_cmd_ready;

    wire [27:0]  mem_addr;

    wire [127:0] mem_wr_data;
    wire [15:0]  mem_wr_strb;
    wire         mem_wr_last;
    wire         mem_wr_valid;
    wire         mem_wr_ready;

    wire [127:0] mem_rd_data;
    wire         mem_rd_last;
    wire         mem_rd_valid;

    wire         mem_sr_en;         // Self-refresh
    wire         mem_sr_done;

    wire         mem_calibrated;

    wire [5:0]   mem_bursts;

    ddr3_mif mif(
        .clk       (hclk),
        .memory_clk(clk_ddr),
        .pll_lock  (clk_ddr_lock),
        .clk_out   (clk_internal),
        .rst_n     (clk_ddr_lock),

        .cmd_ready     (mem_cmd_ready), 
        .cmd           (mem_cmd), 
        .cmd_en        (mem_cmd_valid), 

        .addr          (mem_addr),

        .wr_data_rdy   (mem_wr_ready),
        .wr_data       (mem_wr_data), 
        .wr_data_en    (mem_wr_valid),
        .wr_data_end   (mem_wr_last), 
        .wr_data_mask  (mem_wr_strb), 

        .rd_data       (mem_rd_data), 
        .rd_data_valid (mem_rd_valid),
        .rd_data_end   (mem_rd_last), 

        .sr_req        (mem_sr_en),
        .ref_req       (1'b0),        // Manual refresh, not used
        .sr_ack        (mem_sr_done),
        .ref_ack       ( ),           // Manual refresh done, not used

        .init_calib_complete(mem_calibrated),

        .ddr_rst       ( ),           // Output ready signal, not used
        .burst         (1'b1),        // Always BL8
        .app_burst_number(mem_bursts),

        .O_ddr_addr   (ddr_addr_o),
        .O_ddr_ba     (ddr_ba_o),
        .O_ddr_cs_n   (ddr_cs_n_o), 
        .O_ddr_ras_n  (ddr_ras_n_o),
        .O_ddr_cas_n  (ddr_cas_n_o),
        .O_ddr_we_n   (ddr_we_n_o), 
        .O_ddr_clk    (ddr_clk_o),
        .O_ddr_clk_n  (ddr_clk_n_o),
        .O_ddr_cke    (ddr_cke_o), 
        .O_ddr_odt    (ddr_odt_o), 
        .O_ddr_reset_n(ddr_reset_n_o),
        .O_ddr_dqm    (ddr_dqm_o), 
        .IO_ddr_dq    (ddr_dq_io), 
        .IO_ddr_dqs   (ddr_dqs_io), 
        .IO_ddr_dqs_n (ddr_dqs_n_io)
    );

    // VDMA
    reg  [15:0] tdata_video_d_0, tdata_video_d_1;
    reg         tvalid_video_d_0, tvalid_video_d_1;

    always @(posedge hclk, negedge hresetn) begin
        if(!hresetn) begin
            tdata_video_d_0  <= 16'h0;
            tdata_video_d_1  <= 16'h0;
            tvalid_video_d_0 <= 1'b0;
            tvalid_video_d_1 <= 1'b0;
        end
        else begin
            tdata_video_d_0  <= tdata_video;
            tdata_video_d_1  <= tdata_video_d_0;
            tvalid_video_d_0 <= tvalid_video;
            tvalid_video_d_1 <= tvalid_video_d_0;
        end
    end
    wire [15:0] vout_data;
    wire        vout_nextframe;
    wire        vout_fetch;
    wire        vout_valid;

    vdma vdma_0( 
        .I_dma_clk            (clk_internal ), 
        .I_rst_n              (mem_calibrated ),

        // Ping-pong buffer
        .I_wr_halt            (1'd0 ),
        .I_rd_halt            (1'd0 ),

        // Graphic input             
        .I_vin0_clk          ( hclk ),
        .I_vin0_vs_n         ( ~tuser_video),
        .I_vin0_de           ( tvalid_video),
        .I_vin0_data         ( tdata_video),
        .O_vin0_fifo_full    ( ),

        // Graphic output           
        .I_vout0_clk        (clk_pixel ),
        .I_vout0_vs_n       (vout_nextframe ),
        .I_vout0_de         (vout_fetch ),
        .O_vout0_den        (vout_valid ),
        .O_vout0_data       (vout_data ),
        .O_vout0_fifo_empty ( ),

        // DDR
        .I_cmd_ready          (mem_cmd_ready ),
        .O_cmd                (mem_cmd ),
        .O_cmd_en             (mem_cmd_valid ),
        .O_app_burst_number   (mem_bursts ),
        .O_addr               (mem_addr ),
        .I_wr_data_rdy        (mem_wr_ready ),
        .O_wr_data_en         (mem_wr_valid ),
        .O_wr_data_end        (mem_wr_last ),
        .O_wr_data            (mem_wr_data ),
        .O_wr_data_mask       (mem_wr_strb ),
        .I_rd_data_valid      (mem_rd_valid ),
        .I_rd_data_end        (mem_rd_last ),
        .I_rd_data            (mem_rd_data ),
        .I_init_calib_complete(mem_calibrated)
    );

    // Stream to video out
    stream_2_video_out s2vout (
      .clk     (hclk ),
      .reset_n (hresetn ),

      .sdata      (vout_data ),
      .snextframe (vout_nextframe ),
      .sfetch     (vout_fetch ),
      .svalid     (vout_valid ),

      .video_r       (vout_r ),
      .video_b       (vout_b ),
      .video_g       (vout_g ),
      .hsync         (vout_hsync ),
      .vsync         (vout_vsync ),
      .hblank        ( ),
      .vblank        ( ),
      .active_video  (vout_active )
    );

    // HDMI output
    hdmi_tx hdmi_tx_0(
		.I_rst_n   (hresetn), //input I_rst_n
		.I_rgb_clk (clk_pixel), //input I_rgb_clk

        .I_rgb_r  (vout_r), //input [7:0] I_rgb_r
		.I_rgb_g  (vout_g), //input [7:0] I_rgb_g
		.I_rgb_b  (vout_b), //input [7:0] I_rgb_b
		.I_rgb_vs (vout_vsync), //input I_rgb_vs
		.I_rgb_hs (vout_hsync), //input I_rgb_hs
		.I_rgb_de (vout_active), //input I_rgb_de

		.O_tmds_clk_p  (tmds_clk_p), //output O_tmds_clk_p
		.O_tmds_clk_n  (tmds_clk_n), //output O_tmds_clk_n
		.O_tmds_data_p (tmds_data_p), //output [2:0] O_tmds_data_p
		.O_tmds_data_n (tmds_data_n) //output [2:0] O_tmds_data_n
	);

endmodule