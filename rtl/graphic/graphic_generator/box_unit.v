/*
    box_unit.v
    Box unit
*/

module box_unit(
    input wire clk,
    input wire reset_n,

    input  wire [11:0]  width,
    input  wire [3:0]   fg_color,
    input  wire [3:0]   bg_color,       // Unused
    
    output reg  [3:0]   pix_out,
    output reg  [11:0]  delta_x,
    output reg          wr,
    
    input  wire start,
    output reg  done
);
    
    // Box FSM
    reg  [11:0] width_cnt;
    reg  [1:0]  stat;

    localparam STAT_IDLE = 2'b00;
    localparam STAT_DRAW = 2'b01;
    localparam STAT_DONE = 2'b10;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            width_cnt <= 12'h0;

            stat      <= STAT_IDLE;
        end
        else begin
            case(stat)
            STAT_IDLE:begin
                if(start) begin
                    width_cnt <= width;
                    stat      <= STAT_DRAW;
                end
            end
            STAT_DRAW:begin
                if(width_cnt == 0)
                    stat <= STAT_DONE;
                else
                    width_cnt <= width_cnt - 1;
            end
            STAT_DONE:stat <= STAT_IDLE;
            endcase
        end
    end

    always @(*) begin
        case(stat)
        STAT_IDLE:begin
            pix_out = 4'h0;
            delta_x = 0;
            wr      = 1'b0;

            done    = 1'b0;
        end
        STAT_DRAW:begin
            pix_out = fg_color;
            delta_x = width_cnt;
            wr      = 1'b1;

            done    = 1'b0;
        end
        STAT_DONE:begin
            pix_out = 4'h0;
            delta_x = 0;
            wr      = 1'b0;

            done    = 1'b1;
        end
        default:begin
            pix_out = 4'h0;
            delta_x = 0;
            wr      = 1'b0;

            done    = 1'b0;
        end
        endcase
    end
endmodule