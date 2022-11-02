/*
    chart_unit.v
*/
module chart_unit(
    input  wire clk,
    input  wire reset_n,

    // Parameters
    input  wire [11:0] dy,

    input  wire        [5:0]  kx,
    input  wire        [5:0]  bx,
    input  wire signed [5:0]  ky,
    input  wire signed [10:0] by,
    input  wire [15:0] color_0,
    input  wire [15:0] color_1,
    input  wire        waterfall,

    // Pixel output
    output wire [11:0] dx,
    output wire [15:0] pixel,
    output wire        pixel_wr,
    
    // Buffer read
    output wire        [11:0] buff_addr,
    input  wire signed [15:0] buff_data,

    // Control signals
    input  wire        start,
    output reg         done
);

    // Counter and control FSM
    reg  [9:0] x;
    reg        stat;
    reg        done_0, done_1;

    localparam STAT_IDLE = 2'b00;
    localparam STAT_RUN  = 2'b01;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            x      <= 0;
            done_0 <= 1'b0;
            done_1 <= 1'b0;
            done   <= 1'b0;
            stat   <= 0;      
        end
        else begin
            case(stat)
            STAT_IDLE:begin
                if(start)
                    stat <= STAT_RUN;
            end
            STAT_RUN:begin
                if(x == 1023) begin
                    x      <= 0;
                    stat   <= STAT_IDLE;
                end
                else
                    x <= x + 1;
            end
            endcase

            done_0 <= (x == 1023);
            done_1 <= done_0;
            done   <= done_1;
        end
    end

    always @(*) begin
        
    end

    assign buff_addr = x;

    // x calculation
    reg  [8:0]  x_op;
    reg  [14:0] x_prop;
    reg  [10:0] x_map;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            x_op   <= 9'd0;
            x_prop <= 15'd0;
            x_map  <= 11'd0;
        end
        else begin
            x_op   <= x[9:1];
            x_prop <= x_op * kx;
            x_map  <= x_prop[14:4];
        end
    end

    assign dx = x_map;

    // y calculation
    wire signed [8:0]  y_op = buff_data >>> 7;
    reg  signed [14:0] y_prop;
    wire signed [10:0] y_prop_sh = y_prop >>> 4;
    reg  signed [9:0]  y_map; 
    wire signed [10:0] y_map_u_0 = y_map + (1 << 9);
    wire        [9:0]  y_map_u   = y_map_u_0[9:0];
    
    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            y_prop <= 14'd0;
            y_map  <= 11'd0;
        end
        else begin
            y_prop <= ky * y_op;
            y_map  <= (y_prop_sh + by) >>> 2;
        end
    end

    assign pixel_wr = waterfall ? 1'b1 : ((y_map_u) == dy);

    // Color
    wire signed [4:0] r0 = color_0[4:0];
    wire signed [4:0] b0 = color_0[10:5];
    wire signed [4:0] g0 = color_0[15:10];
    wire signed [4:0] r1 = color_1[4:0];
    wire signed [4:0] b1 = color_1[9:5];
    wire signed [4:0] g1 = color_1[15:10];

    reg  signed [14:0] r_prop, b_prop;
    reg  signed [14:0] g_prop;
    wire signed [4:0]  r_prop_trim = r_prop[14:10];
    wire signed [4:0]  b_prop_trim = b_prop[14:10];
    wire signed [5:0]  g_prop_trim = g_prop[14:9];
    reg  signed [4:0]  r_map, b_map;
    reg  signed [5:0]  g_map;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            r_prop <= 5'd0;
            b_prop <= 5'd0;
            g_prop <= 6'd0;

            r_map  <= 5'd0;
            b_map  <= 5'd0;
            g_map  <= 6'd0;
        end
        else begin
            r_prop <= r1 * y_op;
            b_prop <= b1 * y_op;
            g_prop <= g1 * y_op;

            r_map  <= (r_prop_trim + r0 + (1 << 4));
            b_map  <= (b_prop_trim + b0 + (1 << 4));
            g_map  <= (g_prop_trim + g0 + (1 << 5));
        end
    end

    assign pixel = {r_map, b_map, g_map};
endmodule