/*
    adc_input_parallel.v
    Parallel ADC Input
    Status: Validated, Async clock safe

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

// TODO: Add complement output function
module adc_input_parallel #(
    parameter DW_ADC = 10,
    parameter DW_BUS = 16,
    parameter FILL   = "MSB",
    parameter ADC_IQ = 1
) (
    input  wire adc_clk_in,
    input  wire ce,

    // ADC Interface
    output wire              adc_clk,
    output wire              adc_channel_sel,

    input  wire [DW_ADC-1:0] adc_data,

    // AXI-Stream Signals
    input  wire aclk,
    input  wire aresetn,

    output reg  [DW_BUS-1:0]   tdata_m_out,
    output reg  [DW_BUS/4-1:0] tstrb_m_out,
    output reg                 tid_m_out,

    output reg                 tvalid_m_out,
    input  wire                tready_m_in
);

    // ADC Interface
    reg [DW_BUS-1:0] adc_data_filled;
    reg adc_id;

    reg tready_feedback;

    always @(posedge adc_clk_in, negedge aresetn) begin
        if(!aresetn) begin
            adc_data_filled <= 0;
            adc_id          <= 1'b0;
        end
        else begin
        if(ce) begin
            if(tready_feedback) begin
                // Fill the data to bus width
                if(FILL == "MSB")
                    adc_data_filled <= {adc_data, {(DW_BUS-DW_ADC){1'b0}}};
                else if(FILL == "LSB")
                    adc_data_filled <= {{(DW_BUS-DW_ADC){1'b0}}, adc_data};
                else
                    $error("[ADC_Input] A wrong filling mode is assigned.");

                // Switch the ADC if it's a I/Q dual ADC
                if(ADC_IQ == 1)
                    adc_id <= ~adc_id;
                else
                    adc_id <= 1'b1;
            end
        end
        end
    end

    always @(negedge adc_clk_in, negedge aresetn) begin
        if(!aresetn)
            tready_feedback <= 1'b0;
        else
            // Sample tready signal to adc clock domain.
            // The input is halted if tready = 1
            tready_feedback <= tready_m_in;
    end

    // Channel select output = ID of the ADC
    assign adc_channel_sel = adc_id;
    // Assign ADC clock
    assign adc_clk = adc_clk_in && tready_feedback;

    // AXI-Stream interface
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn) begin
            tdata_m_out <= 0;
            tstrb_m_out <= 0;
            tid_m_out   <= 0;

            tvalid_m_out <= 0;
        end
        else begin
        if(ce) begin
            if(tvalid_m_out && tready_m_in) begin
                tdata_m_out  <= adc_data_filled;
                tstrb_m_out  <= 4'b1111;
                tid_m_out    <= ~adc_id;
            end

            tvalid_m_out <= 1'b1;
        end
        end
    end
endmodule