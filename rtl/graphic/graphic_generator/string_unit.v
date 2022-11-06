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


module string_unit(
    input clk,
    input reset_n,
    input start,
    input [3:0] delta_y,
    input [3:0] fg_color,
    input [3:0] bg_color,
    input [11:0] addr,
    input [7:0] char_in,
    output addr_out,
    output done,
    output [7:0] delta_x,
    output [3:0] pix_out,
    output wr
    
    
    );
    
    wire [3:0] delay_y;
    wire [7:0] char;
    wire en;
    wire data;
    
    addr_in addr_in_U0(
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .delta_y(delta_y),
        .addr(addr),
        .addr_out(addr_out),
        .char_in(char_in),
        .delay_y_out(delay_y),
        .char(char),
        .en(en)
        );
    
    string_out string_out_U1(
        .clk(clk),
        .reset_n(reset_n),
        .delta_y(delay_y),
        .en(en),
        .done(done),
        .data(data),
        .delta_x(delta_x),
        .char(char),
        .wr(wr)
        );

    FB FB_U2(
        .start(start),
        .fg_color(fg_color),
        .bg_color(bg_color),
        .data(data),
        .pix_out(pix_out)
        );

endmodule


module string_out(
    input clk,
    input reset_n,
    input [3:0] delta_y,
    input en,
    output reg done,
    output reg data,
    output reg [7:0] delta_x,
    input [7:0] char,
    output reg wr
    );
    
    reg [7:0] string_rom [0:1023];      //��ģrom
    
    reg [7:0] string_reg;              //��ģ����   
    
    reg [7:0] char_data;                //��ַ����
    reg [7:0] char_data1;                
    reg [3:0] y;                        //delta_y����
    reg [3:0] y1;
    reg [3:0] x;                        // delta_x���棨��˼��������ܣ�                     
    reg [7:0] count;                    //���뻺��
    
    reg [1:0] FSM;                      //״̬��
    reg state;                          //ָʾģ���Ƿ���ʹ�õĻ���
    
    wire [15:0] addr;                   //��ַ�� ����Ѱַ
    wire [7:0] case_1;                  //ѡ���·
    wire case_2;                        //ѡ���·
    
    always@(posedge clk)
    begin
        char_data1 <= char;
        y1 <= delta_y;
    end
    //��ַ����
    assign addr = (char_data << 2) + y;
    
    //��ģ��ȡ
    task string_read();
    begin
        if(~reset_n)
            string_reg <= 8'd0;
        else if(state)
            string_reg <= string_rom[addr];
        else
            string_reg <= 8'd0;
    end
    endtask
    
    //����
    task count_x();
    begin
        if(~reset_n)
            x <= 3'd0;
        else if(x == 3'd7)
            x <= 3'd0;
        else
            x = x + 1'd1;
    end
    endtask
    
    //�ȶ����
    assign case_1 = count & string_reg;
    assign case_2 = |case_1;
    
    //���
    task out();
    begin
        data <= case_2;
        delta_x <= x;
        if(x == 3'd7)
            done <= 1'b1;
        else
            done <= 1'b0;
    end
    endtask
    
    localparam STRING_OUT = 2'b01;
    localparam DATA_OUT = 2'b10;
    localparam IDLE = 2'b00;
    
    //FSM
    always@(posedge clk or negedge reset_n)
    begin
    if(~reset_n)
        begin
        FSM <= IDLE;
        x <= 3'd0;
        y <= 3'd0;
        string_reg <= 8'd0;
        done <= 1'b0;
        data <= 1'b0;
        delta_x <= 'd0;
        char_data <= 'd0;
        state <= 1'b0;
        count <= 'd0;
        wr <= 1'b0;
        end
    else
        case(FSM)
        IDLE:begin
            state <= 1'b0;
            wr <= 1'b0;
            done <= 1'b0;
            data <= 1'b0;
            string_reg <= 8'd0;
            char_data <= 'd0;
            x <= 3'd0;
            delta_x <= 'd0;
            count <= 'd0; 

            if(state)
                FSM <= STRING_OUT;
            
            if(en)
            begin   
                state <= 1'b1;
                char_data <= char_data1;
                y <= y1;
            end
        end
        STRING_OUT:begin
            string_read();
            wr <= 1'b0; 
            FSM <= DATA_OUT;
        end
        DATA_OUT:begin
            wr <= 1'b1;
            if(x == 3'd7)
                begin
                out(); 
                count_x();
                FSM <= IDLE;
                end 
            else
                begin
                out(); 
                count_x();
                end        
        end
    endcase
    
    end
    
    //������
    always@(*)
    begin
    case(x)
    3'd0: count <= 8'b00000001;
    3'd1: count <= 8'b00000010;
    3'd2: count <= 8'b00000100;
    3'd3: count <= 8'b00001000;
    3'd4: count <= 8'b00010000;
    3'd5: count <= 8'b00100000;
    3'd6: count <= 8'b01000000;
    3'd7: count <= 8'b10000000;
    endcase
    end
    
endmodule


module addr_in(
    input clk,
    input reset_n,
    input start,
    input [3:0] delta_y,
    input [11:0] addr,
    input [7:0] char_in,
    output reg [11:0] addr_out,
    output reg [3:0] delay_y_out,
    output reg [7:0] char,
    output reg en
    );
    
    reg state;
    reg [11:0] addr_out1;
    reg [3:0] delay_y_out1;
    
    always@(posedge clk, negedge reset_n)     
        begin
            if(!reset_n) begin
                addr_out <= 'd0;
                delay_y_out <= 'd0;
                char <= 'd0;
                en <= 1'b0;
                state <= 1'b0;
            end
            else begin
                addr_out1 <= addr;
                delay_y_out1 <= delta_y;
                delay_y_out <= delay_y_out1;

                if(start) begin
                    addr_out <= addr_out1;
                    state <= 1'b1;
                end
            end
        end
    
    always@(posedge clk)     
        begin
            if(state)
                begin
                char <= char_in;
                en <= 1'b1;
                state <= 1'b0;
                end
            else
                begin
                en <= 1'b0;
                end
        end    
      
endmodule


module FB(
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