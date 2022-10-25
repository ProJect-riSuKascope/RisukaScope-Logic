/*
    cic_dec_tb.v
    Testbench of Variable Ratio CIC Decimator

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
`timescale 1ns/100ps

module cic_dec_tb();
	// Parameters
	localparam PERIOD_CLK = 10;

    // Signals
    reg  clk, reset_n;

    // DUT
    wire [15:0] tdata_i, tdata_o;
    wire        tvalid_i, tvalid_o;
    wire        tready_i, tready_o;

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
    assign      hsel = (haddr[31:16] == 16'h0000);
  
	cic_decimator_varialble_ahb dut (
		.clk     (clk ),
		.reset_n (reset_n ),
		.ce      (1'b1),

		.tdata_s  (tdata_i ),
		.tvalid_s (tvalid_i ),
		.tready_s (tready_i ),

		.tdata_m  (tdata_o ),
		.tvalid_m (tvalid_o ),
		.tready_m (tready_o ),

		.haddr_s     (haddr ),
		.hburst_s    (hburst ),
		.hsize_s     (hsize ),
		.htrans_s    (htrans),
		.hwdata_s    (hwdata ),
		.hwrite_s    (hwrite ),
		.hrdata_s    (hrdata ),
		.hreadyout_s (hreadyout ),
		.hresp_s     (hresp ),
		.hsel_s      (hsel )
	);

	assign tready_o = 1'b1;

	// Test modules
    cmsdk_ahb_fileread_master32 #(
		.InputFileName ("../tb/dsp/cic/stimulus_cic_dec.m2d"),
		.MessageTag    ("FRBM"),
		.StimArraySize (1023)
    ) ahb_frbm32(
		.HCLK    (clk),
		.HRESETn (reset_n),

		.HREADY    (hreadyout),
		.HRESP     (hresp ),
		.HRDATA    (hrdata ),
		.EXRESP    ( ),
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

    random_wave_axis #(
		.DW        (16 ),
		.PHASE_INC (0.01 )
    ) axis_src(
		.aclk       (clk ),
		.aresetn    (reset_n ),

		.tdata_m_o  (tdata_i ),
		.tvalid_m_o (tvalid_i ),
		.tready_m_i (tready_i )
    );
  
    // Testbench process
    initial begin
        clk        = 1'b0;

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