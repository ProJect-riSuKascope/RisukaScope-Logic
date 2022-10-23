/*
    fir_symmetry_mc.v
    32-stage FIR audio input filter, programmable

    Copyright 2021 Hiryuu T. (PFMRLIB)

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

module fir_symmetry_mc#(
    parameter DW   = 16,       //! Width of data
    parameter NUMW = 18,       //! Quantized fixed coefficient width
    parameter N    = 8,        //! Cycles to finish the calculation

    parameter SECTIONS = 4,    //! FIR sections, stages = SECTIONS * CYCLE

    parameter COEFF_PATH = "coeff.mem"  //! Initial coefficient file path
)(
    input  wire sys_clk,        //! System clock
    input  wire reset_n,        //! Reset, active low
    input  wire ce,             //! Clock enable

    // Input data
    input  wire aclk,     //! Sample clock

    input  wire [DW-1:0] tdata_s_i,
    input  wire          tvalid_s_i,
    output reg           tready_s_o,

    // Output data
    output wire [DW-1:0] tdata_m_o,
    output reg           tvalid_m_o,
    input  wire          tready_m_i,

    /* Coefficient control */
    input  wire [7:0]  coeff_addr,      //! Coefficient address
    input  wire [31:0] coeff_wdata,     //! Coefficient data input
    input  wire        coeff_wr         //! Coefficient write enable
);

    /* clog2 */
    function integer clog2; 
    input integer n; 
    begin 
        n = n - 1; 
        for (clog2 = 0; n > 0; clog2 = clog2 + 1) 
            n = n >> 1; 
    end 
    endfunction

    localparam LGN = clog2(N);

    /* Coefficient memory */
    reg signed [DW*SECTIONS-1:0] coeffs[0:N];
    initial begin
        $readmemh(COEFF_PATH,coeffs);
    end

    integer i;
    always @(posedge sys_clk, negedge reset_n) begin
        if(!reset_n) begin
            for(i = 0;i < N;i = i + 1)
                coeffs[i] <= 'h0;
        end
        else begin
        if(ce) begin
            if(coeff_wr) begin
                if(DW*SECTIONS <= 32)
                    coeffs[coeff_addr] <= coeff_wdata;
                else if(DW*SECTIONS <= 64) begin
                    if(coeff_addr[0])
                        coeffs[coeff_addr][DW*SECTIONS-1:32] <= coeff_wdata;
                    else
                        coeffs[coeff_addr][31:0] <= coeff_wdata;
                end
                else if(DW*SECTIONS <= 128) begin
                    case(coeff_addr[1:0])
                        2'b00:coeffs[coeff_addr][31:0]  <= coeff_wdata;
                        2'b01:coeffs[coeff_addr][63:32] <= coeff_wdata;
                        2'b10:coeffs[coeff_addr][95:64] <= coeff_wdata;
                        2'b11:coeffs[coeff_addr][DW*SECTIONS-1:96] <= coeff_wdata;
                    endcase
                end
                else
                    $display("Coefficient memory width larger than 128 bits is not supported. Currently %d.", DW*SECTIONS);
            end
        end
        end
    end

    /* Cycle generator */
    reg  [3:0] cycle;

    always @(posedge aclk, negedge reset_n) begin
        if(!reset_n)
            cycle <= 4'h0;
        else begin
            if(cycle == N-1)
                cycle <= 4'h0;
            else
                cycle <= cycle + 4'h1;
        end
    end

    /* FIR sections */
    wire signed [DW-1:0]     f[0:SECTIONS];
    wire signed [DW-1:0]     b[0:SECTIONS];
    wire signed [DW+LGN-1:0] r[0:SECTIONS-1];

    assign f[0] = tdata_s_i;

    genvar j;
    generate
        for(j = 0;j < SECTIONS;j = j + 1) begin:gen_sections
            fir_section_symmetry_mc #(
                .DW  (DW),
                .NUMW(NUMW),
                .N   (N),
                .LGN (LGN)
            ) firsec(
                .aclk(aclk),
                .reset_n   (reset_n),
                .ce        (ce),

                .cycle  (cycle),

                .f_prev (f[j]),
                .f_next (f[j+1]),

                .b_next (b[j+1]),
                .b_prev (b[j]),

                .result (r[j]),

                .coeff  (coeffs[cycle][j*DW+:DW])
            );
          
        end
    endgenerate

    assign b[SECTIONS] = f[SECTIONS];

    /* Accumulator */
    reg  signed [DW+LGN+clog2(SECTIONS+1)-1:0] sum;     // Result sum of the sections (without endpoint)

    always @(posedge aclk, negedge reset_n) begin
        if(!reset_n) begin
            sum  <= 'h0;
        end
        else begin
            if(cycle == 2) begin
                case(SECTIONS)     // TODO: Rewite this with FOR loop
                    1:sum <= r[0];
                    2:sum <= r[0] + r[1];
                    3:sum <= r[0] + r[1] + r[2];
                    4:sum <= r[0] + r[1] + r[2] + r[3];
                endcase
            end
        end
    end

    assign tdata_m_o = sum;
endmodule