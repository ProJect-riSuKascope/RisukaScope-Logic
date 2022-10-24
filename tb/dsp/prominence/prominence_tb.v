/*
    prominence_tb.v
    Testbench of stream buffer

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

module prominence_tb();
	// Parameters
	localparam PERIOD_CLK = 10;

    // Signals
    reg  clk, reset_n;

    // DUT
    wire [15:0] tdata;
    wire        tlast;
    wire        tuser;
    wire        tvalid;
    wire        tready;

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

    prominence_analysis #(
      .DW          (16 )
    ) dut(
        .clk (clk ),
        .reset_n (reset_n ),
        .ce (1'b1 ),

        .tdata_s (tdata ),
        .tuser_s (tuser ),
		.tlast_s (tlast),
        .tvalid_s (tvalid ),
        .tready_s (tready ),

        .haddr_s     (haddr ),
        .hburst_s    (hburst ),
        .hsize_s     (hsize ),
        .htrans_s    (htrans ),
        .hwdata_s    (hwdata ),
        .hwrite_s    (hwrite ),
        .hrdata_s    (hrdata ),
        .hreadyout_s (hreadyout ),
        .hresp_s     (hresp ),
        .hsel_s      (hsel )
    );
  

    // Test modules
    cmsdk_ahb_fileread_master32 #(
		.InputFileName ("../tb/dsp/prominence/stimulus_prom.m2d"),
		.MessageTag    ("FRBM"),
		.StimArraySize (1024)
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

    random_wave_axis #(
		.DW        (16 ),
		.PHASE_INC (0.01 )
    ) axis_src(
		.aclk       (clk ),
		.aresetn    (reset_n ),

		.tdata_m_o  (tdata ),
		.tvalid_m_o (tvalid ),
		.tready_m_i (tready )
    );
  
    // Testbench process
    initial begin
        clk = 1'b0;

        reset_n = 1'b0;
        repeat(10) @(posedge clk);
        reset_n = 1'b1;
    end

    always #(PERIOD_CLK/2) clk = ~clk;

	// Frame counter
	reg  [15:0] idx;
	assign tlast = (idx == 0);
	assign tuser = (idx == 1023);

	always @(posedge clk, negedge reset_n) begin
		if(!reset_n)
			idx <= 'd1023;
		else begin
			if(tvalid && tready) begin
				if(idx == 0)
					idx <= 'd1023;
				else
					idx <= idx - 1;
			end
		end
	end

    always begin
        repeat(100000) @(posedge clk);
        $stop();
    end
endmodule