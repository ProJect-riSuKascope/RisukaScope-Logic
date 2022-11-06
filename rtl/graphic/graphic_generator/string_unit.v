`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/01 21:31:49
// Design Name: 
// Module Name: string_out
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module string_unit#(
    parameter MIF_FONTROM = "font_rom.mem"
)(
    input  wire clk,
    input  wire reset_n,
    
    input  wire [3:0]  delta_y,
    input  wire [3:0]  fg_color,
    input  wire [3:0]  bg_color,
    input  wire [11:0] base_addr,
    input  wire [1:0]  scale,

    input  wire [7:0]  char_data,
    output reg  [11:0] char_addr,
    
    output reg [7:0] delta_x,
    output reg [3:0] pix_out,
    output reg       wr,

    input  wire start,
    output reg  done
);

    // Font ROM
    reg  [31:0] font_rom [0:511];
    initial begin
        $readmemh(MIF_FONTROM, font_rom);
    end

    reg  [31:0] font_rom_r;
    reg  [8:0]  font_rom_addr;

    always @(posedge clk) begin
        font_rom_r <= font_rom[font_rom_addr];     
    end

    // String FSM
    reg  [2:0]  stat;
    reg  [3:0]  scale_cnt_max;
    reg  [3:0]  scale_cnt_x, scale_cnt_y;
    reg  [3:0]  char_x, char_y;

    reg  [7:0]  font_line;

    localparam STAT_IDLE  = 3'b000;
    localparam STAT_READ  = 3'b001;
    localparam STAT_DRAW  = 3'b010;
    localparam STAT_DONE  = 3'b011;
    localparam STAT_RECH0 = 3'b100;
    localparam STAT_RECH1 = 3'b101;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            font_line <= 8'h0;

            char_x    <= 'h0;
            char_y    <= 'h0;
            char_addr <= 'h0;

            scale_cnt_x   <= 'h0;
            scale_cnt_y   <= 'h0;
            scale_cnt_max <= 'h0;

            delta_x <= 'h0;

            stat <= STAT_IDLE;
        end
        else begin
            case(stat)
            STAT_IDLE:begin
                if(start) begin
                    delta_x   <= 0;
                    char_addr <= base_addr;

                    case(scale)
                    2'b00:scale_cnt_max <= 4'd0;        // x1
                    2'b10:scale_cnt_max <= 4'd1;        // x2
                    2'b10:scale_cnt_max <= 4'd3;        // x4
                    2'b11:scale_cnt_max <= 4'd7;        // x8
                    endcase

                    stat   <= STAT_READ;
                end
            end
            STAT_READ:begin
                stat <= STAT_RECH0;
            end
            STAT_RECH0:begin
                font_line <= font_rom_r;        // The 32-bit word including a line

                stat      <= STAT_RECH1;
            end
            STAT_RECH1:begin
                case(char_y[1:0])
                2'b00:font_line   <= font_rom_r[7:0];
                2'b01:font_line   <= font_rom_r[15:8];
                2'b10:font_line   <= font_rom_r[23:16];
                2'b11:font_line   <= font_rom_r[31:24];
                default:font_line <= 32'h0000_0000;
                endcase

                scale_cnt_x <= scale_cnt_max;
                char_x      <= 4'd0;
                char_y      <= delta_y >> scale_cnt_max;

                stat        <= STAT_DRAW;
            end
            STAT_DRAW:begin
                if(char_data == 7'h0)           // '\0'
                    stat <= STAT_DONE;
                else begin     
                    if(scale_cnt_x == 0) begin
                        if(char_x == 4'd7) begin
                            stat      <= STAT_READ;          // Read next char
                            char_addr <= char_addr + 1;
                        end
                        else
                            char_x <= char_x + 1;
                    end
                    else
                        scale_cnt_x <= scale_cnt_x - 1;

                    delta_x <= delta_x + 1;
                end
            end
            STAT_DONE:begin
                stat <= STAT_IDLE;
            end
            endcase
        end
    end

    reg        pix_sel;
    reg  [7:0] bit_mask; 

    always @(*) begin
        case(stat)
        STAT_IDLE:begin
            // Interface
            pix_out   = 4'h0;

            wr        = 1'b0;
            done      = 1'b0;

            // Font read
            font_rom_addr = 'h0;

            // Line read
            bit_mask  = 'h0;
            pix_sel   = 1'h0;
        end
        STAT_READ:begin
            // Interface
            pix_out   = 4'h0;
            
            wr        = 1'b0;
            done      = 1'b0;

            // Font read
            font_rom_addr = 'h0;

            // Line read
            bit_mask  = 'h0;
            pix_sel   = 1'h0;
        end
        STAT_RECH0:begin
            // Interface
            pix_out   = 4'h0;
            
            wr        = 1'b0;
            done      = 1'b0;

            // Font read
            if((delta_y & 4'b0100))     // Bottom 4 lines
                font_rom_addr = {char_data, 1'b1};
            else                        // Upper 4 lines
                font_rom_addr = {char_data, 1'b0};

            // Line read
            bit_mask  = 'h0;
            pix_sel   = 1'h0;
        end
        STAT_RECH1:begin
            // Interface
            pix_out   = 4'h0;
            
            wr        = 1'b0;
            done      = 1'b0;

            // Font read
            font_rom_addr = 'h0;

            // Line read
            bit_mask  = 'h0;
            pix_sel   = 1'h0;
        end
        STAT_DRAW:begin
            // Interface
            if(pix_sel)
                pix_out = fg_color;
            else
                pix_out = bg_color;
            
            wr        = 1'b1;        // Write
            done      = 1'b0;

            // Font read
            font_rom_addr = 'h0;

            // Line read
            bit_mask = 8'b00000001 << char_x;
            pix_sel  = |(bit_mask & font_line);
        end
        STAT_DONE:begin
            // Interface
            pix_out   = 4'h0;
            
            wr        = 1'b0;
            done      = 1'b0;

            // Font read
            font_rom_addr = 'h0;

            // Line read
            bit_mask  = 'h0;
            pix_sel   = 1'h0;
        end
        endcase
    end
endmodule