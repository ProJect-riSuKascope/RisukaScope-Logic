/*
    dsp_subsystem_tb.v
    Testbench of DSP subsystem
*/
`timescale 1ns/100ps
module dsp_subsystem_tb ();
    	// Parameters
	localparam PERIOD_CLK = 10;

    // Signals
    reg  clk, reset_n;

    // DUT
    wire [31:0] tdata;
    wire        tlast;
    wire        tuser;
    wire        tvalid;
    wire        tready;
    wire        interrupts;

    wire [31:0] haddr;
    wire [2:0]  hburst;
    wire [2:0]  hsize;
    wire [1:0]  htrans;
    wire [31:0] hwdata;
    wire        hwrite;
    wire [31:0] hrdata;
    wire        hreadyout;
    wire        hresp;
    
    wire        hsel;
    assign      hsel = (haddr[31:24] == 16'h000);

    dsp_subsystem dut (
        .hclk    (clk ),
        .hresetn (reset_n ),
        .ce      (1'b1),

        .tdata_s   (tdata ),
        .tvalid_s  (tvalid ),
        .tready_s  (tready),

        .haddr_s     (haddr ),
        .hburst_s    (hburst ),
        .hsize_s     (hsize ),
        .htrans_s    (htrans ),
        .hwdata_s    (hwdata ),
        .hwrite_s    (hwrite ),
        .hrdata_s    (hrdata ),
        .hreadyout_s (hreadyout ),
        .hresp_s     (hresp ),
        .hsel_s      (hsel ),

        .interrupts (interrupts)
    );

    // Test modules
    cmsdk_ahb_fileread_master32 #(
		.InputFileName ("../tb/dsp/stimulus_dsp_subsys.m2d"),
		.MessageTag    ("FRBM"),
		.StimArraySize (16384)
    ) ahb_frbm32(
		.HCLK    (clk),
		.HRESETn (reset_n),

		.HREADY    (hreadyout),
		.HRESP     (hresp ),
		.HRDATA    (hrdata ),
		.EXRESP    (1'b0),
		.HTRANS    (htrans ),
		.HBURST    (hburst ),
		.HPROT     ( ),
		.EXREQ     ( ),
		.MEMATTR   ( ),
		.HSIZE     (hsize ),
		.HWRITE    (hwrite ),
		.HMASTLOCK ( ),
		.HADDR     (haddr ),
		.HWDATA    (hwdata ),

		.LINENUM  ( )
    );

    wire [15:0] data_i = tdata[15:0];
    wire [15:0] data_q = tdata[31:16];

    random_wave_axis #(
		.DW        (16 ),
		.PHASE_INC (0.001 )
    ) axis_src_i(
		.aclk       (clk ),
		.aresetn    (reset_n ),

		.tdata_m_o  (tdata[15:0] ),
		.tvalid_m_o (tvalid ),
		.tready_m_i (tready )
    ) ;
    random_wave_axis #(
		.DW        (16 ),
		.PHASE_INC (0.01 )
    ) axis_src_q(
		.aclk       (clk ),
		.aresetn    (reset_n ),

		.tdata_m_o  (tdata[31:16] ),
		.tvalid_m_o (),
		.tready_m_i ()
    );
  
    // Testbench process
    initial begin
        clk = 1'b0;

        reset_n = 1'b0;
        repeat(10) @(posedge clk);
        reset_n = 1'b1;
    end

    always #(PERIOD_CLK/2) clk = ~clk;

    always begin
        repeat(10000000) @(posedge clk);
        $stop();
    end
endmodule