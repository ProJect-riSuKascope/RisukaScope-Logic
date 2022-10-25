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
    parameter DW = 16
) (
    // Global clock and reset
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // AXI-Stream interface
    input  wire signed [DW-1:0] tdata_s,
    input  wire                 tuser_s,
    input  wire                 tlast_s,
    input  wire                 tvalid_s,
    output reg                  tready_s,

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

    input  wire            hsel_s,

    // Interrupt output
    output wire            interrupt
);

    // Peak/Valley/Flat detection
    reg  signed [15:0] val_last, val_last_1;     // Last value
    reg  signed [15:0] diff, diff_last;          // Value difference
    reg                frame_start, frame_end;   // Frame start & end

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            val_last    <= 0;
            val_last_1  <= 0;

            diff        <= 0;
            diff_last   <= 0;

            frame_start <= 1'b0;
        end
        else begin
        if(ce) begin
            if(tvalid_s && tready_s) begin
                diff        <= tdata_s - val_last;
                diff_last   <= diff;
                val_last    <= tdata_s;
                val_last_1  <= val_last;

                frame_start <= tuser_s;
            end
        end
        end
    end

    wire peak   = (diff < 0) && (diff_last >= 0);
    wire valley = (diff > 0) && (diff_last <= 0);
    wire flat   = peak && valley;

    // Index counter
    reg  [9:0]  idx, idx_last;          // Data index

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

    // Registers
    reg  [31:0] reg_ctrl;
    reg  [31:0] reg_stat;

    // Register and control fields
    // Number of the values to be sort
    wire [3:0]  sort_count    = reg_ctrl[19:16];
    wire        start_oneshot = reg_ctrl[1];
    wire        start_cont    = reg_ctrl[2];
    wire        interrupt_en  = reg_ctrl[3];

    // Sort module signals
    reg  [15:0] prom_rdata;
    wire [15:0] prom_raddr;

    // Prominence FSM
    localparam STAT_IDLE   = 4'b0000;
    localparam STAT_PEAK   = 4'b0001;     // Find a peak
    localparam STAT_VALLEY = 4'b0010;     // Find a valley
    localparam STAT_WRPROM = 4'b0011;     // Write prominence data to buffer
    localparam STAT_SORT   = 4'b0100;
    localparam STAT_SORTWR = 4'b0101;
    localparam STAT_CLEAR  = 4'b0110;     // Clear the buffer
    localparam STAT_DONE   = 4'b0111;     // Empty state to set DONE flag in status register
    localparam STAT_WAIT   = 4'b1000;     // Wait for data
    localparam STAT_WRVAL  = 4'b1011;
    localparam STAT_WRIDX  = 4'b1100;
    localparam STAT_SORWAT = 4'b1101;     // Wait state inserted before sort

    reg  [3:0] stat;

    // Prominences find
    reg  signed [15:0] peak_val;
    reg  signed [15:0] last_valley_val;

    wire signed [16:0] prom_left      = peak_val - last_valley_val;
    wire signed [16:0] prom_right     = peak_val - val_last_1;
    wire        [15:0] prom_left_u    = prom_left[15:0];
    wire        [15:0] prom_right_u   = prom_left[15:0];

    // Prominence values
    reg  signed [15:0] prominence;
    reg  signed [9:0]  prom_idx;
    // Sort values
    reg         [7:0]  sort_idx;
    reg         [7:0]  sort_idx_max;
    reg         [15:0] sort_data;
    reg         [15:0] sort_max;
    reg         [15:0] sort_max_last;
    reg         [3:0]  sort_cnt;

    reg         [9:0]  sorted [0:15];

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n)
            frame_end <= 1'b0;
        else begin
            if(tvalid_s && tready_s) begin
                if((stat != STAT_WRPROM) && (stat != STAT_WRVAL) && (stat != STAT_WRIDX))
                    frame_end <= tlast_s;
            end
        end
    end

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            stat <= STAT_IDLE;

            peak_val <= 0;
            last_valley_val <= 0;

            prominence <= 0;
            prom_idx   <= 0;

            sort_idx      <= 0;
            sort_idx_max  <= 0;
            sort_max      <= 0;
            sort_max_last <= 0;
            sort_cnt      <= 0;
        end
        else begin
        if(ce) begin
            case(stat)
            STAT_IDLE:begin
                if(start_oneshot || start_cont)
                    stat <= STAT_CLEAR;
            end
            STAT_CLEAR:begin
                // Clear buffer
                if(prom_idx == 0)
                    stat <= STAT_WAIT;
                else begin
                    prom_idx <= prom_idx - 1;
                end
            end
            STAT_WAIT:begin
                if(frame_start) begin
                    if(diff > 0)
                        stat <= STAT_PEAK;
                    else
                        stat <= STAT_VALLEY;

                    last_valley_val <= val_last_1;
                end
            end
            STAT_PEAK:begin
                if(frame_end) begin
                    // Calculate the last prominence at the end of sequence
                    // Last value as peak
                    prominence <= val_last_1 - last_valley_val;
                    stat <= STAT_WRPROM;
                end
                else if(peak) begin       // Peak found
                    peak_val <= val_last_1;

                    stat <= STAT_VALLEY;
                end
            end
            STAT_VALLEY:begin
                if(valley || frame_end) begin     // Valley found, or it's the end value
                    if(last_valley_val > val_last_1)
                        // Current valley is higher.
                        prominence <= prom_right_u;
                    else
                        // The last valley is higher.
                        prominence <= prom_left_u;

                    last_valley_val <= val_last_1;

                    stat <= STAT_WRPROM;
                end
            end
            STAT_WRPROM:stat <= STAT_WRVAL;
            STAT_WRVAL:stat <= STAT_WRIDX;
            STAT_WRIDX:begin
                prom_idx <= prom_idx + 1;

                // Check index
                if(frame_end) begin
                    stat          <= STAT_SORWAT;
                    // Set last maximum value to the maximum digit to update to the largest value
                    sort_max_last <= (1 << DW) - 1;
                end
                else
                    stat <= STAT_PEAK;
            end
            STAT_SORWAT:stat <= STAT_SORT;      // Interval state for sort data loading
            STAT_SORT:begin
                if(sort_idx == prom_idx) begin
                    stat     <= STAT_SORTWR;
                    sort_idx <= 0;
                end
                else
                    sort_idx  <= sort_idx + 1;

                // Update maximum value
                if((sort_data > sort_max) && (sort_data < sort_max_last)) begin
                    sort_max     <= sort_data;
                    sort_idx_max <= sort_idx - 1;
                end
            end
            STAT_SORTWR:begin
                // Stop sorting if count of sort value is fullfilled
                if(sort_cnt == sort_count) begin
                    sort_cnt <= 0;
                    sort_max <= 0;
                    sort_idx <= 0;

                    stat     <= STAT_DONE;
                end
                else begin
                    // Record the value
                    sorted[sort_cnt] <= sort_idx_max;

                    sort_max_last <= sort_max;
                    sort_max      <= 0;
                    sort_cnt      <= sort_cnt + 1;
                    sort_idx      <= 0;
                    sort_idx_max  <= 0;

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

    reg  [9:0]  buffer_addr_m;
    reg  [15:0] buffer_wdata_m;
    reg  [15:0] buffer_rdata_m;
    reg         buffer_wr_m;

    always @(*) begin
        case(stat)
        STAT_CLEAR:begin
            tready_s    = 1'b0;

            buffer_addr_m = prom_idx;
            buffer_wdata_m = 0;
            buffer_wr_m   = 1'b1;

            sort_data = buffer_rdata_m;
        end
        STAT_PEAK, STAT_WAIT:begin
            tready_s    = 1'b1;

            buffer_addr_m = 'h0;
            buffer_wdata_m = 0;
            buffer_wr_m = 1'b0;

            sort_data = buffer_rdata_m;
        end
        STAT_VALLEY:begin
            tready_s    = ~frame_end;

            buffer_addr_m = 'h0;
            buffer_wdata_m = 0;
            buffer_wr_m = 1'b0;

            sort_data = buffer_rdata_m;
        end
        STAT_WRPROM:begin
            tready_s    = 1'b0;

            buffer_addr_m  = {2'b00, {prom_idx[7:0]}};
            buffer_wdata_m = prominence;
            buffer_wr_m   = 1'b1;

            sort_data = buffer_rdata_m;
        end
        STAT_WRVAL:begin
            tready_s    = 1'b0;

            buffer_addr_m = {2'b01, {prom_idx[7:0]}};
            buffer_wdata_m = peak_val;
            buffer_wr_m   = 1'b1;

            sort_data = buffer_rdata_m;
        end
        STAT_WRIDX:begin
            tready_s    = 1'b0;

            buffer_addr_m  = {2'b10, {prom_idx[7:0]}};
            buffer_wdata_m = idx_last;
            buffer_wr_m    = 1'b1;

            sort_data = buffer_rdata_m;
        end
        STAT_SORWAT:begin
            tready_s    = 1'b0;

            buffer_addr_m  = {2'b00, 8'd0};
            buffer_wdata_m = 0;
            buffer_wr_m    = 1'b0;

            sort_data = buffer_rdata_m;
        end
        STAT_SORT, STAT_SORTWR:begin
            tready_s    = 1'b0;

            buffer_addr_m  = {2'b00, {sort_idx[7:0]}};
            buffer_wdata_m = 0;
            buffer_wr_m    = 1'b0;

            sort_data = buffer_rdata_m;
        end
        default:begin
            tready_s = 1'b0;

            buffer_addr_m  = 0;
            buffer_wdata_m = 0;
            buffer_wr_m    = 1'b0;

            sort_data = 0;
        end
        endcase
    end

    // Prominence buffer, external access
    wire [9:0]  buffer_addr_i = haddr_s[11:2];
    reg  [15:0] buffer_rdata_i;

    // Prominence buffer
    // The buffer is devided into three 1024x16b BRAMs
    // The syntheizer is quite silly
    /* synthesis syn_ramstyle = "block_ram" */
    reg  [16:0] prom_buff [0:767];

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            buffer_rdata_m <= 0;
            buffer_rdata_i <= 0;
        end
        else begin
        if(ce) begin
            buffer_rdata_i <= prom_buff[buffer_addr_i];
            
            if(buffer_wr_m)
                prom_buff[buffer_addr_m] <= buffer_wdata_m;
            else
                buffer_rdata_m <= prom_buff[buffer_addr_m];
        end
        end
    end

    `include "ahb_intf_prominence.v"
endmodule