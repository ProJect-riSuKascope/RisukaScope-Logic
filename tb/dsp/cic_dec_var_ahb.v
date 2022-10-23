/*
    cic_dec_var_ahb.v
    Testbench of Variable Sample Rate CIC Decimator

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

module cic_dec_var_ahb();
    // Parameters
    localparam DUT_BUS_ADDR = 'h0000_0000;
    localparam DUT_PERI_AW  = 8;

    localparam DUT_STREAM_WIDTH = 16;

    localparam TEST_CTRL   = 1;     // Test AHB control interface
    localparam TEST_STREAM = 1;     // Test AXI-Stream Interface

    // Signals
    reg clk, reset_n;

    // AXI-Stream
    wire [31:0] tdata_in;
    wire        tvalid_in;
    wire        tready_in;

    wire [31:0] tdata_out;
    wire        tvalid_out;
    wire        tready_out;

    // AHB
    wire [31:0] haddr;
    wire [2:0]  hburst;
    wire [3:0]  hprot;
    wire [2:0]  hsize;
    wire [1:0]  htrans;
    wire [31:0] hwdata;
    wire        hwrite;
    wire [31:0] hrdata;
    wire        hreadyout;
    wire        hresp;

    // DUT
    cic_decimator_varialble_ahb #(
      .INPUT_DW (16),
      .OUTPUT_DW(16),

      .BUS_ADDR    (32'h0000_0000),
      .BUS_PERI_AW (8)
    ) cic_decimator_varialble_ahb_dut(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (1'b1),

      .tdata_s_in  (tdata_in),
      .tvalid_s_in (tvalid_in),
      .tready_s_in (tready_in),

      .tdata_m_out  (tdata_out),
      .tvalid_m_out (tvalid_out),
      .tready_m_out (tready_out),

      .haddr_i  (haddr),
      .hburst_i (hburst),
      .hprot_i  (hprot),
      .hsize_i  (hsize),
      .htrans_i (htrans),
      .hwdata_i (hwdata),
      .hwrite_i (hwrite),
      .hrdata_o (hrdata),

      .hreadyout_o (hreadyout),
      .hresp_o     (hresp),
      .hsel_i      (1'b1)
    );
  
endmodule