/*
    prominence_analysis.v
    Analysis the peak values of a sequence

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
module prominence_analysis #(
    parameter DW = 16,

    // AHB Bus address
    parameter BUS_ADDR    = 32'h0000_0001,
    parameter BUS_PERI_AW = 8
) (
    // Global clock and reset
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // AXI-Stream interface
    input  wire signed [2*DW-1:0] tdata_s,
    input  wire                   tuser_s,
    input  wire                   tvalid_s,
    output wire                   tready_s,

    // AHB Control Interface
    // HCLK, HRESETn are combined into global signals.
    input  wire [31:0]     haddr_s,
    input  wire [2:0]      hburst_s,
    // Locked sequence (HMASTLOCK) is not used.
    // Protection option (HPROT[6:0]) is not used.
    input  wire [2:0]      hsize_s,
    // Secure transfer (HNONSEC) is not used.
    // Exclusive transfer (HEXCL) is not used.
    // Master identifier (HMASTER[3:0]) is not used.
    input  wire [1:0]      htrans_s,
    input  wire [31:0]     hwdata_s,
    input  wire            hwrite_s,

    output reg  [31:0]     hrdata_s,
    output reg  [31:0]     hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire            hsel_s
);

    // Peak/Valley/Flat detection
    reg  signed [15:0] val_last;                 // Last value
    reg  signed [15:0] diff, diff_last;          // Value difference

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            val_last <= 0;

            diff      <= 0;
            diff_last <= 0;
        end
        else begin
        if(ce) begin
            if(tvalid_s && tready_s) begin
                diff      <= tdata_s - val_last;
                diff_last <= diff;
                val_last  <= tdata_s;
            end
        end
        end
    end

    wire peak   = (diff < 0) && (diff_last >= 0);
    wire valley = (diff > 0) && (diff_last <= 0);
    wire flat   = peak && valley;

    // Index counter
    reg  [9:0]  idx, idx_last;          // Data index
    reg         start;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            idx      <= 10'h0;
            idx_last <= 10'h0;
        end
        else begin
        if(ce) begin
            if(tvalid_s && tready_s) begin
                if(idx == 10'd1023)
                    idx <= 10'h0;
                else
                    idx <= idx + 1;

                idx_last <= idx;
            end
        end
        end
    end

    // AXI-Stream ready feedback
    assign tready_s = (stat == STAT_IDLE) || (stat == STAT_VALLEY) || (stat == STAT_PEAK);

    // Register and control fields
    // Number of the values to be sort
    wire [3:0]  sort_count = reg_ctrl[19:16];

    // Registers
    reg  [31:0] reg_ctrl;
    reg  [31:0] reg_stat;

    // Prominence buffer
    reg  [47:0] prom_buff   [0:1023];

    // Sort module signals
    reg  [15:0] prom_rdata;
    wire [15:0] prom_raddr;

    // Prominence FSM
    localparam STAT_IDLE   = 3'b000;
    localparam STAT_PEAK   = 3'b001;     // Find a peak
    localparam STAT_VALLEY = 3'b010;     // Find a valley
    localparam STAT_WRITE  = 3'b011;     // Write prominence data to buffer
    localparam STAT_SORT   = 3'b100;
    localparam STAT_SORTWR = 3'b101;
    localparam STAT_CLEAR  = 3'b110;     // Clear the buffer
    localparam STAT_DONE   = 3'b111;     // Empty state to set DONE flag in status register

    reg  [2:0] stat;

    // Prominences find
    reg  signed [15:0] peak_val;
    reg  signed [15:0] last_valley_val;
    // Prominence values
    reg  signed [15:0] prominence;
    reg                prom_valid;
    reg  signed [9:0]  prom_idx;
    // Sort values
    reg         [7:0]  sort_idx;
    reg         [7:0]  sort_idx_max;
    reg  signed [15:0] sort_data;
    reg  signed [15:0] sort_max;
    reg         [3:0]  sort_cnt;

    reg         [47:0] sorted [0:15];
    reg         [47:0] sort_max_aux;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            stat <= STAT_IDLE;

            peak_val <= 0;
            last_valley_val <= 0;

            prominence <= 0;
            prom_idx   <= 0;

            prom_rdata <= 1'b0;
        end
        else begin
        if(ce) begin
            case(stat)
            STAT_IDLE:begin
                if(start)
                    stat <= STAT_CLEAR;
            end
            STAT_CLEAR:begin
                // Clear buffer
                if(prom_idx == 0) begin
                    if(diff > 0)
                        stat <= STAT_PEAK;
                    else
                        stat <= STAT_VALLEY;

                    last_valley_val <= val_last;
                end
                else begin
                    prom_buff[prom_idx] <= 0;
                    prom_idx            <= prom_idx - 1;
                end
            end
            STAT_PEAK:begin
                if(idx_last == 1023) begin
                    // Calculate the last prominence at the end of sequence
                    // Last value as peak
                    prominence <= val_last - last_valley_val;

                    stat <= STAT_WRITE;
                end
                else if(peak) begin       // Peak found
                    peak_val <= val_last;

                    stat <= STAT_VALLEY;
                end
            end
            STAT_VALLEY:begin
                if(valley || (idx_last == 1023)) begin     // Valley found, or it's the end value
                    if((peak_val - val_last) > (peak_val - last_valley_val))
                        // Current valley is higher.
                        prominence <= peak_val - val_last;
                    else
                        // The last valley is higher.
                        prominence <= peak_val - last_valley_val;

                    stat <= STAT_WRITE;
                end
            end
            STAT_WRITE:begin
                // Write prominence value to buffer
                prom_buff[prom_idx] <= {peak_val, idx_last, prominence};
                prom_idx            <= prom_idx + 1;

                // Check index
                if(idx_last == 1023)
                    stat <= STAT_SORT;
                else
                    stat <= STAT_PEAK;
            end
            STAT_SORT:begin
                if(sort_idx == 1023) begin
                    stat          <= STAT_SORTWR;
                    sort_max_aux <= prom_buff[sort_idx_max];
                end
                else begin
                    sort_idx  <= sort_idx + 1;
                    sort_data <= prom_buff[sort_idx][15:0];
                end

                // Update maximum value
                if(sort_data > sort_max) begin
                    sort_max     <= sort_data;
                    sort_idx_max <= sort_idx;
                end
            end
            STAT_SORTWR:begin
                // Stop sorting if count of sort value is fullfilled
                if(sort_cnt == sort_count)
                    stat     <= STAT_DONE;
                else begin
                    // Record the value
                    sorted[sort_cnt] <= sort_max_aux;

                    sort_cnt     <= sort_cnt + 1;
                    sort_idx     <= 0;
                    sort_idx_max <= 0;

                    // Set the maximum value to 0 to find another maximum value
                    prom_buff[sort_idx_max] <= 0;

                    stat <= STAT_SORT;
                end
            end
            STAT_DONE:begin
                stat <= STAT_IDLE;
            end
            endcase
        end
        end
    end
endmodule