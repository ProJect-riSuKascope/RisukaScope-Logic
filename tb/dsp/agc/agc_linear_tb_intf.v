/*
    agc_linear_tb_intf.v
    Testbench of linear AGC, AHB interface

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

module agc_linear_tb_intf();
    // Parameters
    localparam STIM_FILE = "../tb/dsp/agc/stimulus.m2d";

    reg clk, reset_n;

    // DUT
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

    assign hsel = (haddr[31:16] == 16'h0000);

    agc_linear #(
      .DW (16),
      .K  (100)
    ) dut(
      .clk     (clk),
      .reset_n (reset_n ),
      .ce      (1'b1),

      .tdata_s  (16'h0),
      .tvalid_s (1'b0),
      .tready_s ( ),

      .tdata_m  ( ),
      .tvalid_m ( ),
      .tready_m (1'b1),

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
        .InputFileName(STIM_FILE), 
        .MessageTag   ("FRBM"),
        .StimArraySize(5000)
    )ahb_frbm (
        .HCLK            (clk),
        .HRESETn         (reset_n),

        .HREADY          (hreadyout),
        .HRESP           (hresp),    // AHB Lite response to AHB response
        .HRDATA          (hrdata),
        .EXRESP          (1'b0),     //  Exclusive response (tie low if not used)

        .HTRANS          (htrans),
        .HBURST          (hburst),
        .HPROT           ( ),
        .EXREQ           ( ),        //  Exclusive access request (not used)
        .MEMATTR         ( ),        //  Memory attribute (not used)
        .HSIZE           (hsize),
        .HWRITE          (hwrite),
        .HMASTLOCK       ( ),
        .HADDR           (haddr),
        .HWDATA          (hwdata),

        .LINENUM         ()
    );

    // Test process
    initial begin
        clk     = 1'b0;
        reset_n = 1'b0;
    end

    always #5 clk = ~clk;

    always begin
        reset_n = 1'b0;
        repeat(10) @(negedge clk);
        reset_n = 2'b1;
        
        repeat(1000000) @(negedge clk);
        $stop();
    end
endmodule