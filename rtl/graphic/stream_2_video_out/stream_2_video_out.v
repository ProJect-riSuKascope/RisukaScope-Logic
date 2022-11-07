/*
    stream_2_video_out.v
    Video stream to Video Out, with Timing Generator and External FIFO
*/
module stream_2_video_out (
    input  wire clk,
    input  wire reset_n,

    // AXI-Stream video data input
    input  wire [15:0] tdata_s,
    output wire        tlast_s,
    input  wire        tuser_s,
    input  wire        tvalid_s,
    output reg         tready_s,

    // Video output
    output reg  [4:0]  video_r,
    output reg  [4:0]  video_b,
    output reg  [5:0]  video_g,
    output reg         hsync,
    output reg         vsync,
    output reg         hblank,
    output reg         vblank,
    output reg         active_video
);

    // Display paramerters
    localparam PIX_H_FPORCH = 24;
    localparam PIX_H_BPORCH = 144;
    localparam PIX_H_SYNC   = 136;
    localparam PIX_H_ACTIVE = 1024;
    localparam PIX_H_TOTAL  = 1328;

    localparam PIX_V_FPORCH = 3;
    localparam PIX_V_BPORCH = 29;
    localparam PIX_V_SYNC   = 6;
    localparam PIX_V_ACTIVE = 768;
    localparam PIX_V_TOTAL  = 806;

    // Derived timing parameters
    localparam HFPCH_START = PIX_H_ACTIVE;
    localparam HFPCH_END   = PIX_H_FPORCH + PIX_H_ACTIVE;
    localparam HSYNC_START = PIX_H_FPORCH + PIX_H_ACTIVE;
    localparam HSYNC_END   = PIX_H_FPORCH + PIX_H_ACTIVE + PIX_H_SYNC;
    localparam HBPCH_START = PIX_H_FPORCH + PIX_H_ACTIVE + PIX_H_SYNC;
    localparam HBPCH_END   = PIX_H_TOTAL;

    localparam VFPCH_START = PIX_V_ACTIVE;
    localparam VFPCH_END   = PIX_V_FPORCH + PIX_V_ACTIVE;
    localparam VSYNC_START = PIX_V_FPORCH + PIX_V_ACTIVE;
    localparam VSYNC_END   = PIX_V_FPORCH + PIX_V_ACTIVE + PIX_V_SYNC;
    localparam VBPCH_START = PIX_V_FPORCH + PIX_V_ACTIVE + PIX_V_SYNC;
    localparam VBPCH_END   = PIX_V_TOTAL;

    // Counter
    reg  [11:0] x, y;
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            x <= 0;
            y <= 0;
        end
        else begin
            if(x == PIX_H_TOTAL - 1) begin
                x <= 0;

                if(y == PIX_V_TOTAL - 1)
                    y <= 0;
                else
                    y <= y + 1;
            end
            else
                x <= x + 1;
        end
    end

    // Timing output
    always @(*) begin
        // Active video
        if((x < PIX_H_ACTIVE) && (y < PIX_V_ACTIVE))
            active_video = 1'b1;
        else
            active_video = 1'b0;

        // HSync
        if((x >= HSYNC_START) && (x < HSYNC_END))
            hsync = 1'b1;
        else
            hsync = 1'b0;

        // VSync
        if((y >= VSYNC_START) && (y < VSYNC_END))
            vsync = 1'b1;
        else
            vsync = 1'b0;

        // HBlank
        if((x >= PIX_H_ACTIVE) && (x < PIX_H_TOTAL))
            hblank = 1'b1;
        else
            hblank = 1'b0;

        // VBlank
        if((y >= PIX_V_ACTIVE) && (y < PIX_V_TOTAL))
            vblank = 1'b1;
        else
            vblank = 1'b0;

        video_g = tdata_s[5:0];
        video_b = tdata_s[10:6];
        video_r = tdata_s[15:11];

        tready_s = active_video;
    end
endmodule