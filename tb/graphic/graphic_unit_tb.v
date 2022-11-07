/*
    Graphic_unit_tb.v
    Testbench of graphic unit
*/
`timescale 1ns/100ps

module graphic_unit_tb ();
    // Parameters
	localparam PERIOD_CLK = 10;

    // Signals
    reg  clk, reset_n;

    // DUT
    wire [15:0] tdata;
    wire        tlast;
    wire        tuser;
    wire        tvalid;
    wire        tready = 1'b1;

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
    assign      hsel = (haddr[31:16] == 16'h0001);

    // DUT
    /*
    graphic_generator graphic_generator_dut (
        .hclk    (clk ),
        .hresetn (reset_n ),
        .ce      (1'b1 ),

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

        .tdata_m   (tdata ),
        .tlast_m   (tlast ),
        .tuser_m   (tuser ),
        .tvalid_m  (tvalid ),
        .tready_m  (1'b1)
    );
    */

    graphic_generator #(
        .MIF_INST("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/rtl/graphic/graph_inst_compiler/inst.mem")
        //.MIF_STRING("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/rtl/graphic/graph_inst_compiler/data.mem"),
        //.MIF_CHART("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/rtl/graphic/graph_inst_compiler/chart.mem"),
        //.MIF_PALETTE("D:/Concordia_Projects/Project_PlatinumCollapsaR/fpga/data/palette.mem")
    ) dut(
        .hclk    (clk ),
        .hresetn (reset_n ),
        .ce      (1'b1 ),

        .haddr_s     (0),
        .hburst_s    (3'd0),
        .hsize_s     (3'd0),
        .htrans_s    (2'b00),
        .hwdata_s    (0),
        .hwrite_s    (1'b0),
        .hrdata_s    ( ),
        .hreadyout_s ( ),
        .hresp_s     ( ),

        .hsel_s      (1'b0 ),

        .tdata_m   (tdata ),
        .tlast_m   (tlast ),
        .tuser_m   (tuser ),
        .tvalid_m  (tvalid ),
        .tready_m  (tready)
    );
  

    // Test modules
    /*
    cmsdk_ahb_fileread_master32 #(
		.InputFileName ("../tb/dsp/prominence/stimulus_prom.m2d"),
		.MessageTag    ("FRBM"),
		.StimArraySize (1024)
    ) ahb_frbm32(
		.HCLK      (clk),
		.HRESETn   (reset_n),

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
    */
  
    // Testbench process
    initial begin
        clk = 1'b0;

        reset_n = 1'b0;
        repeat(10) @(posedge clk);
        reset_n = 1'b1;
    end

    always #(PERIOD_CLK/2) clk = ~clk;

    always begin
        repeat(100000) @(posedge clk);
        $stop();
    end
endmodule