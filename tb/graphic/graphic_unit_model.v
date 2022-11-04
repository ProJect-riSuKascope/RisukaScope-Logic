/*
    graphic_unit_model.v
    Universal Model of Graphic Unit
*/
module graphic_unit_model#(
    parameter UNIT_NAME = "UNIT"
)(
    input clk,
    input reset_n,

    // Common inputs
    input  wire [11:0] dy,
    input  wire start,

    // Common outputs
    output reg  [11:0] dx,
    output reg         wr,
    output wire        done,
    output reg         data,

    // Specific parameters
    // String & box
    input  wire [3:0]  fg_color,
    input  wire [3:0]  bg_color,

    // String
    input  wire [11:0] base_addr,
    input  wire [4:0]  scale,

    // Box(Line)
    input       [11:0] width,

    // Chart
    input  wire        [5:0]  kx,
    input  wire        [5:0]  bx,
    input  wire signed [5:0]  ky,
    input  wire signed [10:0] by,
    input  wire [15:0] color_0,
    input  wire [15:0] color_1,
    input  wire        waterfall,

    // Buffer access
    // String
    output reg  [10:0] char_addr,
    input  wire        char_data,
    // Chart
    output reg  [10:0] val_addr,
    input  wire [15:0] val_in,

    // Debug
    output reg  [31:0] cycles
);
    
    // Reset flag
    reg         reseted;

    initial begin
        reseted = 0;
    end

    reg [11:0]  w;

    // Test FSM
    reg  [1:0] stat;

    localparam STAT_IDLE  = 2'b00;
    localparam STAT_START = 2'b01;
    localparam STAT_PROCS = 2'b10;
    localparam STAT_END   = 2'b11;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            if(!reseted) begin
                $display("Module reseted");
                reseted <= 1'b1;
            end

            cycles <= 1'b0;
            stat   <= STAT_IDLE;
        end
        else begin
            case(stat)
            STAT_IDLE:begin
                if(start)
                    stat <= STAT_START; 
            end
            STAT_START:begin
                $display("%8d       Module: %s started", cycles, UNIT_NAME);
                $display("COMMON     dy:%04h", dy);
                $display("STR,BOX    fg_color:%02d    bg_color:%02d", fg_color, bg_color);
                $display("STR        base_addr:%08h   scale:%02d", base_addr, scale);
                $display("CHART      kx:%02d     ky:%02d    bx:%02d    by:%02d", kx, ky, bx, by);
                $display("CHART      color0:(%02d, %02d, %02d)    color1:(%02d, %02d, %02d)", color_0[15:11], color_0[5:0], color_0[10:6], color_1[15:11], color_1[5:0], color_1[10:6]);
                $display("CHART      waterfall:%01d", waterfall);

                stat <= STAT_PROCS;
                w    <= {$random} % 320;
            end
            STAT_PROCS:begin
                if(dx == w)
                    stat <= STAT_END;
                else
                    w    <= w + 1;
            end
            STAT_END:begin
                stat <= STAT_IDLE;
            end
            endcase
            
            cycles <= cycles + 1;
        end
    end

    assign done = (stat == STAT_END);
endmodule