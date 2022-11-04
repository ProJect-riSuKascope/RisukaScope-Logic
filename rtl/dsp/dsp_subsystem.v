/*
    dsp_subsystem.v
    DSP Subsystem

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
module dsp_subsystem(
    input  wire hclk,
    input  wire hresetn,
    input  wire ce,

    // Master AHB interface (Slave as seen by this module)
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
    output reg  [31:0]     hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.
    input  wire            hsel_s,

    // Interrupts
    output wire [7:0]  interrupts,

    // Input AXI-Stream
    input  wire [31:0] tdata_s,
    input  wire        tvalid_s,
    output wire        tready_s
);

    // AHB Slave decoder
    wire hsel_agc, hsel_cic, hsel_cic_comp, hsel_fft_win, 
         hsel_recv_comp, hsel_prom, hsel_spect_buff;
    
    assign hsel_agc        = (haddr_s[31:16] == 16'h0000);
    assign hsel_cic        = (haddr_s[31:16] == 16'h0001);
    assign hsel_cic_comp   = (haddr_s[31:16] == 16'h0002);
    assign hsel_fft_win    = (haddr_s[31:16] == 16'h0003);
    assign hsel_recv_comp  = (haddr_s[31:16] == 16'h0004);
    assign hsel_prom       = (haddr_s[31:16] == 16'h0005);
    assign hsel_spect_buff = (haddr_s[31:16] == 16'h0006);

    // AHB sync bridge
    wire [31:0] haddr_m_syncout;
    wire [1:0]  htrans_m_syncout;
    wire [2:0]  hsize_m_syncout;
    wire        hwrite_m_syncout;
    wire [31:0] hwdata_m_syncout;
    wire [2:0]  hburst_m_syncout;
    wire        hready_m_syncin;
    wire        hresp_m_syncin;
    wire [31:0] hrdata_m_syncin;

    cmsdk_ahb_to_ahb_sync #(
        .AW(32),
        .DW(32),
        .MW(0),
        .BURST(0)
    ) ahb_bridge (
        .HCLK (hclk ),
        .HRESETn (hresetn ),

        .HSELS      (hsel_s ),
        .HADDRS     (haddr_s),
        .HTRANSS    (htrans_s ),
        .HSIZES     (hsize_s ),
        .HWRITES    (hwrite_s ),
        .HREADYS    (hreadyout_s ),
        .HPROTS     (4'b0001),
        .HMASTERS   (1'b0),
        .HMASTLOCKS (1'b0),
        .HWDATAS    (hwdata_s),
        .HBURSTS    (hburst_s),
        .HREADYOUTS (hreadyout_s),
        .HRESPS     (hresp_s),
        .HRDATAS    (hrdata_s),

        .HADDRM     (haddr_m_syncout ),
        .HTRANSM    (htrans_m_syncout ),
        .HSIZEM     (hsize_m_syncout ),
        .HWRITEM    (hwrite_m_syncout ),
        .HPROTM     ( ),
        .HMASTERM   ( ),
        .HMASTLOCKM ( ),
        .HWDATAM    (hwdata_m_syncout ),
        .HBURSTM    (hburst_m_syncout ),
        .HREADYM    (hready_m_syncin ),
        .HRESPM     (hresp_m_syncin ),
        .HRDATAM    (hrdata_m_syncin )
    );

    // AHB slave MUX
    wire [31:0] hrdata_agc;
    wire        hresp_agc;
    wire        hreadyout_agc;

    wire [31:0] hrdata_cic;
    wire        hresp_cic;
    wire        hreadyout_cic;

    wire [31:0] hrdata_cic_comp;
    wire        hresp_cic_comp;
    wire        hreadyout_cic_comp;

    wire [31:0] hrdata_fft_win;
    wire        hresp_fft_win;
    wire        hreadyout_fft_win;

    wire [31:0] hrdata_recv_comp;
    wire        hresp_recv_comp;
    wire        hreadyout_recv_comp;

    wire [31:0] hrdata_prom;
    wire        hresp_prom;
    wire        hreadyout_prom;

    wire [31:0] hrdata_spect_buff;
    wire        hresp_spect_buff;
    wire        hreadyout_spect_buff;

    cmsdk_ahb_slave_mux #(
        .PORT0_ENABLE(1'b1),
        .PORT1_ENABLE(1'b1),
        .PORT2_ENABLE(1'b1),
        .PORT3_ENABLE(1'b1),
        .PORT4_ENABLE(1'b1),
        .PORT5_ENABLE(1'b1),
        .PORT6_ENABLE(1'b1),
        .PORT7_ENABLE(1'b0),
        .PORT8_ENABLE(1'b0),
        .PORT9_ENABLE(1'b0),
        .DW (32)
    ) ahb_slave_mux_0 (
        .HCLK (hclk ),
        .HRESETn (hresetn ),

        .HREADY    (1'b1 ),               // No cascade
        .HRESP     (hresp_m_syncin ),
        .HRDATA    (hrdata_m_syncin ),
        .HREADYOUT (hready_m_syncin ),

        .HSEL0      (hsel_agc ),
        .HREADYOUT0 (hreadyout_agc ),
        .HRESP0     (hresp_agc ),
        .HRDATA0    (hrdata_agc ),

        .HSEL1      (hsel_cic ),
        .HREADYOUT1 (hreadyout_cic ),
        .HRESP1     (hresp_cic ),
        .HRDATA1    (hrdata_cic ),

        .HSEL2      (hsel_cic_comp ),
        .HREADYOUT2 (hreadyout_cic_comp ),
        .HRESP2     (hresp_cic_comp ),
        .HRDATA2    (hrdata_cic_comp ),

        .HSEL3      (hsel_fft_win ),
        .HREADYOUT3 (hreadyout_fft_win ),
        .HRESP3     (hresp_fft_win ),
        .HRDATA3    (hrdata_fft_win ),

        .HSEL4      (hsel_recv_comp ),
        .HREADYOUT4 (hreadyout_recv_comp ),
        .HRESP4     (hresp_recv_comp ),
        .HRDATA4    (hrdata_recv_comp ),

        .HSEL5      (hsel_prom ),
        .HREADYOUT5 (hreadyout_prom ),
        .HRESP5     (hresp_prom ),
        .HRDATA5    (hrdata_prom ),

        .HSEL6      (hsel_spect_buff ),
        .HREADYOUT6 (hreadyout_spect_buff ),
        .HRESP6     (hresp_spect_buff ),
        .HRDATA6    (hrdata_spect_buff )

        // The followed ports are disabled.
        //.HSEL7 (HSEL7 ),
        //.HREADYOUT7 (HREADYOUT7 ),
        //.HRESP7 (HRESP7 ),
        //.HRDATA7 (HRDATA7 ),

        //.HSEL8 (HSEL8 ),
        //.HREADYOUT8 (HREADYOUT8 ),
        //.HRESP8 (HRESP8 ),
        //.HRDATA8 (HRDATA8 ),

        //.HSEL9 (HSEL9 ),
        //.HREADYOUT9 (HREADYOUT9 ),
        //.HRESP9 (HRESP9 ),
        //.HRDATA9 (HRDATA9 ),
    );
  
    // DSP Modules
    // Modulus
    wire [15:0] tdata_mod_raw;
    wire        tvalid_mod_raw;
    wire        tready_mod_raw;

    modulus #(
        .DW (16 )
    )modulus_raw (
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_s ),
        .tvalid_s (tvalid_s ),
        .tready_s (tready_s ),
        
        .tdata_m  (tdata_mod_raw ),
        .tvalid_m (tvalid_mod_raw ),
        .tready_m (tready_mod_raw )
    );

    // Decimator
    wire [15:0] tdata_decimated;
    wire        tvalid_decimated;
    wire        tready_decimated;

    cic_decimator_varialble_ahb cic0 (
      .clk (hclk ),
      .reset_n (hresetn ),
      .ce (1'b1 ),

      .tdata_s  (tdata_mod_raw ),
      .tvalid_s (tvalid_mod_raw ),
      .tready_s (tready_mod_raw ),

      .tdata_m  (tdata_decimated ),
      .tvalid_m (tvalid_decimated ),
      .tready_m (tready_decimated ),

      .haddr_s     (haddr_m_syncout ),
      .hburst_s    (hburst_syncout ),
      .hsize_s     (hsize_syncout ),
      .htrans_s    (htrans_syncout ),
      .hwdata_s    (hwdata_syncout ),
      .hwrite_s    (hwrite_syncout ),

      .hrdata_s    (hrdata_cic ),
      .hreadyout_s (hreadyout_cic ),
      .hresp_s     (hresp_cic ),
      .hsel_s      (hsel_cic)
    );

    wire [15:0] tdata_dec_comped;
    wire        tvalid_dec_comped;
    wire        tready_dec_comped;

    fir_bram_mc #(
        .DW(16 ),
        .MEM_FILE (MEM_FILE_CICC )
    ) fir_cic_comp(
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_decimated ),
        .tvalid_s (tvalid_decimated ),
        .tready_s (tready_decimated ),

        .tdata_m  (tdata_dec_comped ),
        .tvalid_m (tvalid_dec_comped ),
        .tready_m (tready_dec_comped ),

        .haddr_s     (haddr_m_syncout ),
        .hburst_s    (hburst_syncout ),
        .hsize_s     (hsize_syncout ),
        .htrans_s    (htrans_syncout ),
        .hwdata_s    (hwdata_syncout ),
        .hwrite_s    (hwrite_syncout ),

        .hrdata_s    (hrdata_cic_comp ),
        .hreadyout_s (hreadyout_cic_comp ),
        .hresp_s     (hresp_cic_comp ),

        .hsel_s      (hsel_cic_comp)
    );
  
    wire [15:0] tdata_framed;
    wire        tlast_framed;
    wire        tvalid_framed;
    wire        tready_framed;

    frame_generation #(
        .DW(16),
        .FRAME_LEN (1024)
    ) frame_div(
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_dec_comped ),
        .tvalid_s (tvalid_dec_comped ),
        .tready_s (tready_dec_comped ),

        .tdata_m  (tdata_framed ),
        .tlast_m  (tlast_framed ),
        .tvalid_m (tvalid_framed ),
        .tready_m (tready_framed ),

        .ext_sync (1'b0)
    );
  

    wire [15:0] tdata_fft_win;
    wire        tlast_fft_win;
    wire        tuser_fft_win;
    wire        tvalid_fft_win;
    wire        tready_fft_win;

    fft_window #(
        .DW      (16),
        .MEM_FILE(MEM_FILE_FFTW ),
        .DATA_CNT(1024 )
    ) fft_win_0 (
        .clk     (hclk ),
        .reset_n (hresetn ),

        .tdata_s  (tdata_framed ),
        .tvalid_s (tvalid_framed ),
        .tlast_s  (tlast_framed ),
        .tready_s (tready_framed ),

        .tdata_m  (tdata_fft_win ),
        .tlast_m  (tlast_fft_win ),
        .tvalid_m (tvalid_fft_win ),
        .tready_m (tready_fft_win ),

        .haddr_s     (haddr_m_syncout ),
        .hburst_s    (hburst_syncout ),
        .hsize_s     (hsize_syncout ),
        .htrans_s    (htrans_syncout ),
        .hwdata_s    (hwdata_syncout ),
        .hwrite_s    (hwrite_syncout ),

        .hrdata_s    (hrdata_fft_win ),
        .hreadyout_s (hreadyout_fft_win ),
        .hresp_s     (hresp_fft_win),

        .hsel_s      (hsel_fft_win)    
    );

    wire [15:0] tdata_fft;
    wire        tlast_fft;
    wire        tuser_fft;
    wire        tvalid_fft;
    wire        tready_fft;

    fft_wrapper fft (
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_fft_win ),
        .tlast_s  (tlast_fft_win ),
        .tuser_s  (tuser_fft_win ),
        .tvalid_s (tvalid_fft_win ),
        .tready_s (tready_fft_win ),

        .tdata_m  (tdata_fft ),
        .tuser_m  (tuser_fft ),
        .tlast_m  (tlast_fft ),
        .tvalid_m (tvalid_fft ),
        .tready_m (tready_fft )
    );

    wire [15:0] tdata_recv_comp;
    wire        tlast_recv_comp;
    wire        tuser_recv_comp;
    wire        tvalid_recv_comp;
    wire        tready_recv_comp;

    receiver_compensation #(
      .DW       (16),
      .MEM_FILE (MEM_FILE ),
      .DATA_CNT (1024 )
    ) rec_comp_0(
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_fft ),
        .tlast_s  (tlast_fft ),
        .tuser_s  (tuser_fft ),
        .tvalid_s (tvalid_fft ),
        .tready_s (tready_fft ),

        .tdata_m  (tdata_recv_comp ),
        .tlast_m  (tlast_recv_comp),
        .tuser_m  (tuser_recv_comp),
        .tvalid_m (tvalid_recv_comp ),
        .tready_m (tready_recv_comp ),

        .haddr_s     (haddr_m_syncout ),
        .hburst_s    (hburst_syncout ),
        .hsize_s     (hsize_syncout ),
        .htrans_s    (htrans_syncout ),
        .hwdata_s    (hwdata_syncout ),
        .hwrite_s    (hwrite_syncout ),

        .hrdata_s    (hrdata_recv_comp ),
        .hreadyout_s (hreadyout_recv_comp ),
        .hresp_s     (hresp_recv_comp),

        .hsel_s      (hsel_recv_comp)
    );
  
    // Analysis modules
    stream_buffer spect_buff (
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_recv_comp ),
        .tlast_s  (tlast_recv_comp ),
        .tuser_s  (tuser_recv_comp ),
        .tvalid_s (tvalid_recv_comp ),
        .tready_s ( ),              // The bus is controlled by prominence analysis module

        .haddr_s     (haddr_m_syncout ),
        .hburst_s    (hburst_syncout ),
        .hsize_s     (hsize_syncout ),
        .htrans_s    (htrans_syncout ),
        .hwdata_s    (hwdata_syncout ),
        .hwrite_s    (hwrite_syncout ),

        .hrdata_s    (hrdata_spect_buff ),
        .hreadyout_s (hreadyout_spect_buff ),
        .hresp_s     (hresp_spect_buff ),

        .hsel_s      (hsel_spect_buff)
    );

    prominence_analysis #(
      .DW (16 )
    )prom (
        .clk     (hclk ),
        .reset_n (hresetn ),
        .ce      (1'b1 ),

        .tdata_s  (tdata_recv_comp ),
        .tlast_s  (tlast_recv_comp ),
        .tuser_s  (tuser_recv_comp ),
        .tvalid_s (tvalid_recv_comp ),
        .tready_s (tready_recv_comp),

        .haddr_s     (haddr_m_syncout ),
        .hburst_s    (hburst_syncout ),
        .hsize_s     (hsize_syncout ),
        .htrans_s    (htrans_syncout ),
        .hwdata_s    (hwdata_syncout ),
        .hwrite_s    (hwrite_syncout ),

        .hrdata_s    (hrdata_prom ),
        .hreadyout_s (hreadyout_prom ),
        .hresp_s     (hresp_prom ),
        .hsel_s      (hsel_prom ),

        .interrupt   (interrupts[0])
    );
endmodule