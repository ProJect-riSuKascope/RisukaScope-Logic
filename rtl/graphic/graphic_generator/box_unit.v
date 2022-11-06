`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/03 17:44:07
// Design Name: 
// Module Name: box_out
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

module box_unit(
    input clk,
    input reset_n,
    input start,
    input [3:0] fg_color,
    input [3:0] bg_color,
    output [3:0] pix_out,
    output done,
    output [11:0] delta_x,
    input [11:0] width,
    output wr    
    );
    
    wire en;
    wire data;
    
    assign en = start;
    
    box_out box_out_U0(
        .clk(clk),
        .reset_n(reset_n),
        .en(en),
        .done(done),
        .data(data),
        .delta_x(delta_x),
        .width(width),
        .wr(wr)
        );

    FB_1 FB_1_U1(
        .start(start),
        .fg_color(fg_color),
        .bg_color(bg_color),
        .data(data),
        .pix_out(pix_out)
        );
    
    
    
endmodule

module box_out(
    input clk,
    input reset_n,
    input en,
    output reg done,
    output reg data,
    output reg [11:0] delta_x,
    input [11:0] width,
    output reg wr
    );
    
    
    reg [11:0] width_reg;              //���Ȼ���   
    reg [11:0] width_reg1;
    
    reg [11:0] x;                        // delta_x���棨��˼��������ܣ�                     
    
    reg FSM;                            //״̬��
    reg state;                          //ָʾģ���Ƿ���ʹ�õļĴ���
    
    always@(posedge clk)
    begin
        width_reg1 <= width; 
        if(state)
            width_reg <= width_reg1; 
    end
    
    //����
    task count_x();
    begin
        if(~reset_n)
            x <= 12'd0;
        else if(x == width_reg - 1)
            x <= 12'd0;
        else
            x = x + 12'd1;
    end
    endtask
    
    
    //���
    task out();
    begin
        delta_x <= x;
        if(x == width_reg - 1)
            begin
            done <= 1'b1;
            data <= 1'b1;
            end
        else
            begin
            done <= 1'b0;
            data <= 1'b1;
            end
    end
    endtask
    
    localparam DATA_OUT = 1'b1;
    localparam IDLE = 1'b0;
    
    //FSM
    always@(posedge clk or negedge reset_n)
    begin
    if(~reset_n)
        begin
        FSM <= IDLE;
        x <= 12'd0;
        delta_x <= 12'd0;
        state <= 1'b0;
        done <= 1'b0;
        data <= 1'b0;
        end
    else
        case(FSM)
        IDLE:begin
            wr <= 1'b0;
            done <= 1'b0;
            data <= 1'b0;
            delta_x <= 'd0;
            x <= 'd0;

            if(state)
                FSM <= DATA_OUT;
            if(en)   
                state <= 1'b1;
        end
        DATA_OUT:begin
            wr <= 1'b1;
            if(x == width_reg - 1)
                begin
                out(); 
                count_x();
                FSM <= IDLE;
                state <= 1'b0;
                end 
            else
                begin
                out(); 
                count_x();
                end        
        end
    endcase
    
    end

endmodule

module FB_1(
    input start,
    input [3:0] fg_color,
    input [3:0] bg_color,
    input data, 
    output reg [3:0] pix_out
    );
    
    reg [3:0] fg_reg;
    reg [3:0] bg_reg;
    
    always@(posedge start)
    begin
        fg_reg <= fg_color;
        bg_reg <= bg_color;
    end
    
    always@(*)
    begin
    case(data)
        1'b0:pix_out <= bg_reg;
        1'b1:pix_out <= fg_reg;
    endcase
    end
    

endmodule
