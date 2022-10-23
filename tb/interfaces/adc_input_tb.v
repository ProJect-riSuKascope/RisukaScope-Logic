/*
    adc_input_parallel.sv
    Testbench of Parallel ADC Input Module

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
`timescale 1ns/100ps

module adc_input_tb();
    // Simulation configure
    localparam PERIOD_ADC  = 50;        // 50ns/20MHz
    localparam PERIOD_ACLK = 50;        // 20ns/50MHz

    // Signals
    reg aclk, adc_clk_in;
    reg aresetn;

    wire       adc_clk;
    wire       adc_channel_sel;
    wire [9:0] adc_data;

    wire [15:0] tdata_adc_input;
    wire [1:0]  tstrb_adc_input;
    wire        tid_adc_input;

    wire        tvalid_adc_input;
    wire        tready_adc_input;

    // DUT
    adc_input_parallel #(
      .DW_ADC (10),
      .DW_BUS (16),
      .FILL   ("LSB"),
      .ADC_IQ (1)
    )adc_input_parallel_dut (
      .adc_clk_in (adc_clk_in),
      .ce (1'b1),

      .adc_clk         (adc_clk),
      .adc_channel_sel (adc_channel_sel),
      .adc_data        (adc_data),

      .aclk    (aclk),
      .aresetn (aresetn),
      .tdata_m_out  (tdata_adc_input),
      .tstrb_m_out  (tstrb_adc_input),
      .tid_m_out    (tid_adc_input),
      .tvalid_m_out (tvalid_adc_input),
      .tready_m_in  (tready_adc_input)
    );
  
    // Simulation models
    ad9201_model adc_0(
        .clock (adc_clk),
        .data  (adc_data),
        .select(adc_channel_sel)
    );

    axi_stream_sink #(
      .TDATA_WIDTH  (16),
      .TID_WIDTH    (1),
      .TDEST_WIDTH  (1),
      .TUSER_WIDTH  (1),

      .USE_TKEEP   (0),
      .USE_TLAST   (0),
      .USE_TID     (1),
      .USE_TDEST   (0),
      .USE_TUSER   (0),
      .USE_TWAKEUP (1)
    ) axi_stream_sink_0(
      .aclk       (aclk),
      .aresetn    (aresetn),

      .tdata_s_in   (tdata_adc_input),
      .tstrb_s_in   (tstrb_adc_input),
      .tid_s_in     (tid_adc_input),

      .tvalid_s_in  (tvalid_adc_input),
      .tready_s_out (tready_adc_input)
    );

    // Testbench process
    initial begin
        aclk = 1'b0;
        adc_clk_in = 1'b0;

        aresetn = 1'b0;
        repeat(10) @(posedge aclk);
        aresetn = 1'b1;
    end
  
    always #(PERIOD_ADC/2) adc_clk_in = ~adc_clk_in;
    always #(PERIOD_ACLK/2) aclk = ~aclk;

    always begin
        repeat(100) @(posedge aclk);
        $stop();
    end
endmodule