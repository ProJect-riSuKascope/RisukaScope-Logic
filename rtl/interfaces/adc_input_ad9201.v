/*
    adc_input_ad9201.v
    AD9201 ADC input
*/
module adc_input_ad9201 (
    input  wire       clk,
    input  wire       reset_n,
    
    // ADC input
    input  wire [9:0]  adc_input,
    output reg         adc_iq_sel,
    output reg         adc_clk,

    // AXI-Stream output
    output reg  [31:0] tdata_m,
    output wire        tvalid_m,
    input  wire        tready_m
);

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            adc_clk    <= 1'b0;
            adc_iq_sel <= 1'b0;
            tdata_m    <= 'h0;
        end 
        else begin
            if(adc_iq_sel) begin          // I
                if(adc_input[9])        // Convert to signed
                    tdata_m[15:0]  <= (~adc_input + 1) << 6;
                else
                    tdata_m[15:0] <= adc_input + 1;
            end
            else begin                  // Q
                if(adc_input[9])        // Convert to signed
                    tdata_m[31:16]  <= (~adc_input + 1) << 6;
                else
                    tdata_m[31:17] <= adc_input + 1;
            end

            adc_iq_sel <= ~adc_iq_sel;
        end   
    end

    assign tvalid_m = adc_iq_sel;
endmodule