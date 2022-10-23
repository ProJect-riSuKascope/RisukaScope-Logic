/*
    cic_decimator_variable_ahb.v
    Variable Sample Rate CIC Decimator with AHB Interface

    Copyright 2021-2022 Hiryuu T. (PFMRLIB)

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
module cic_decimator_varialble_ahb#(
    parameter INPUT_DW = 16,
    parameter OUTPUT_DW = 16,

    // AHB Bus address
    parameter BUS_ADDR    = 32'h0000_0001,
    parameter BUS_PERI_AW = 8
)(
    // Clock and reset
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // AXI-Stream I/O
    input  wire [INPUT_DW-1:0] tdata_s_in,
    input  wire                tvalid_s_in,
    output reg                 tready_s_in,

    output reg  [OUTPUT_DW-1:0] tdata_m_out,
    output reg                  tvalid_m_out,
    input  wire                 tready_m_out,

    // AHB Control Interface
    // Master signals
    input  wire [31:0] haddr_i,
    input  wire [2:0]  hburst_i,
    // HMASTLOCK: Not used
    input  wire [3:0]  hprot_i,
    input  wire [2:0]  hsize_i,
    // HNONSEC: Not used
    // HEXCL: Not used
    // HMASTER: Not used
    input  wire [1:0]  htrans_i,
    input  wire [31:0] hwdata_i,
    input  wire        hwrite_i,

    // Slave signals
    output reg  [31:0] hrdata_o,
    output reg         hreadyout_o,
    output reg         hresp_o,
    // HEXOKAY: Not used,

    // Decoder signals
    input  wire        hsel_i
);

    // Control interface
    reg  [31:0] reg_control;
    wire peri_enable = reg_control[0];

    // LSB truncation of each stage
    reg  [31:0] reg_trunc_comb_0;
    reg  [31:0] reg_trunc_comb_1;
    reg  [31:0] reg_trunc_intg_0;
    reg  [31:0] reg_trunc_intg_1;

    wire [7:0] comb_trunc_0 = reg_trunc_comb_0[7:0];
    wire [7:0] comb_trunc_1 = reg_trunc_comb_0[15:8];
    wire [7:0] comb_trunc_2 = reg_trunc_comb_0[23:16];
    wire [7:0] comb_trunc_3 = reg_trunc_comb_0[31:24];
    wire [7:0] comb_trunc_4 = reg_trunc_comb_1[7:0];
    wire [7:0] intg_trunc_0 = reg_trunc_intg_0[7:0];
    wire [7:0] intg_trunc_1 = reg_trunc_intg_0[15:8];
    wire [7:0] intg_trunc_2 = reg_trunc_intg_0[23:16];
    wire [7:0] intg_trunc_3 = reg_trunc_intg_0[31:24];
    wire [7:0] intg_trunc_4 = reg_trunc_intg_1[7:0];

    // Decimate ratio, only low 16 bit is available
    reg  [15:0] reg_dec_ratio;

    // AHB FSM
    reg  [1:0] ahb_stat;
    
    localparam AHB_STAT_IDLE = 2'b00;
    localparam AHB_STAT_ADDR = 2'b01;
    localparam AHB_STAT_WR   = 2'b11;
    localparam AHB_STAT_RD   = 2'b10;

    reg  [31:0] reg_addr;
    reg  [31:0] read_data_internal;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            // Registers
            reg_control    <= 32'h0;

            reg_trunc_comb_0 <= 32'h0;
            reg_trunc_comb_1 <= 32'h0;
            reg_trunc_intg_0 <= 32'h0;
            reg_trunc_intg_1 <= 32'h0;

            reg_dec_ratio <= 0;

            // AHB Bus
            ahb_stat <= AHB_STAT_IDLE;

            hrdata_o    <= 32'h0;
            hreadyout_o <= 1'b1;
            hresp_o     <= 1'b0;        // Always OKAY

            reg_addr <= 32'h0;
        end
        else begin
        if(ce) begin
            case (ahb_stat)
                AHB_STAT_IDLE:begin
                    if(hsel_i)      // With a HSELx signal, address decoding in the peripheral is no more needed.
                        ahb_stat <= AHB_STAT_ADDR;
                end
                AHB_STAT_ADDR:begin
                    reg_addr <= haddr_i[BUS_PERI_AW-1:0];
                    
                    if(hwrite_i)
                        ahb_stat <= AHB_STAT_WR;
                    else
                        ahb_stat <= AHB_STAT_RD;
                end
                AHB_STAT_WR:begin
                    case(reg_addr)
                        'h00:reg_control      <= hwdata_i;
                        'h04:reg_trunc_intg_0 <= hwdata_i;
                        'h08:reg_trunc_intg_1 <= hwdata_i;
                        'h0c:reg_trunc_comb_0 <= hwdata_i;
                        'h10:reg_trunc_comb_1 <= hwdata_i;
                        'h14:reg_dec_ratio    <= hwdata_i[15:0];
                    endcase

                    hreadyout_o <= 1'b1;

                    ahb_stat <= AHB_STAT_IDLE;
                end
                AHB_STAT_RD:begin
                    hrdata_o <= read_data_internal;

                    ahb_stat <= AHB_STAT_IDLE;
                end
            endcase        
        end
        end
    end

    always @(*) begin
        case(reg_addr)
            'h00:read_data_internal <= {16'h0, reg_control};
            'h04:read_data_internal <= reg_trunc_intg_0;
            'h08:read_data_internal <= reg_trunc_intg_1;
            'h0c:read_data_internal <= reg_trunc_comb_0;
            'h10:read_data_internal <= reg_trunc_comb_1;
            'h14:read_data_internal <= reg_trunc_comb_1;
            default:read_data_internal <= reg_control;
        endcase
    end

    // Clock enable with AXI-Stream flow control
    wire ce_stages = ce && tvalid_s_in && tready_s_in;

    // CIC_GENERATOR_BEGIN
    // Generated by Hogenaur Pruning Calculator
    // Time: 2022-9-30 11:48:29
    // Environment: Python 3.10.4 (tags/v3.10.4:9d38120, Mar 23 2022, 23:13:41) [MSC v.1929 64 bit (AMD64)] on win32
    reg  signed [52:0] d_0;
    reg  signed [46:0] d_1;
    reg  signed [38:0] d_2;
    reg  signed [31:0] d_3;
    reg  signed [23:0] d_4;
    reg  signed [22:0] d_5;
    reg  signed [21:0] d_6;
    reg  signed [20:0] d_7;
    reg  signed [19:0] d_8;
    reg  signed [19:0] d_9;

    integrator #(
      .DW (53)
    ) intg_0(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce),

      .din  (tdata_s_in),
      .dout (d_0)
    );

    integrator #(
      .DW (47)
    ) intg_1(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce),

      .din  (d_0 >>> intg_trunc_0),
      .dout (d_1)
    );

    integrator #(
      .DW (39)
    ) intg_2(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce),

      .din  (d_1 >>> intg_trunc_1),
      .dout (d_2)
    );

    integrator #(
      .DW (32)
    ) intg_3(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce),

      .din  (d_2 >>> intg_trunc_2),
      .dout (d_3)
    );

    integrator #(
      .DW (24)
    ) intg_4(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce),

      .din  (d_3 >>> intg_trunc_3),
      .dout (d_4)
    );

    // Resample
    reg         [15:0] cycle;
    
    wire resample_en = (cycle == reg_dec_ratio);

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n)
            cycle <= 0;
        else begin
            if(cycle == reg_dec_ratio)
                cycle <= 0;
            else
                cycle <= cycle + 1;
        end
    end

    comb #(
      .DW (23),
      .M  (2)
    ) comb_0(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce && resample_en),

      .din  (d_4 >>> 1),
      .dout (d_5)
    );

    comb #(
      .DW (22),
      .M  (2)
    ) comb_1(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce && resample_en),

      .din  (d_5 >>> 1),
      .dout (d_6)
    );

    comb #(
      .DW (21),
      .M  (2)
    ) comb_2(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce && resample_en),

      .din  (d_6 >>> 1),
      .dout (d_7)
    );

    comb #(
      .DW (20),
      .M  (2)
    ) comb_3(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce && resample_en),

      .din  (d_7 >>> 1),
      .dout (d_8)
    );

    comb #(
      .DW (20),
      .M  (2)
    ) comb_4(
      .clk     (clk),
      .reset_n (reset_n),
      .ce      (ce && resample_en),

      .din  (d_8),
      .dout (d_9)
    );
  
    // CIC_GENERATOR_END

    // AXI-Stream output
    assign tdata_m_out  = d_9[19:4];
    assign tvalid_m_out = resample_en;
endmodule