/*
    string_fsm.v
    String graphic FSM

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
/*
    Command format:
    x0        y0       x1       y1       color     index    command
    [55:45]   [44:34]  [33:23]  [22:12]  [14:11]   [10:3]   [2:0]

    (x0,y0) --- (x1,y0)
       |           |
       |           |
    (x0,y1) --- (x1,y1)
*/
module string_fsm(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // Command input
    input  wire [63:0]  command,

    // String buffer write
    output reg  [15:0]  str_addr,
    input  wire [7:0]   str_data,
    input  wire         str_rd,

    // Display buffer write
    output reg  [3:0]   buff_data,
    output reg  [11:0]  buff_addr,
    output reg          buff_wr,

    // FSM control
    input  wire         start,
    output reg          done,

    input  wire [10:0]  line
);

    // Font config
    localparam FONT_X = 4;
    localparam FONT_Y = 8;
    // Font ROM
    reg  [31:0] font [0:255];

    // String write FSM
    localparam STAT_IDLE  = 3'd0;
    localparam STAT_FETCH = 3'd1;
    localparam STAT_WRITE = 3'd2;

    reg  [2:0]  stat;
    reg  [11:0] x_pos;
    reg  [7:0]  char;           // Char value
    reg  [7:0]  char_idx;       // Char index in a string

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            
        end
        else begin
        if(ce) begin
            case(stat)
            STAT_IDLE:begin
                if(start)
                    stat <= STAT_FETCH;
            end
            STAT_FETCH:begin
                char      <= buff_data;

                // Set pointer to next char
                char_idx  <= char_idx + 1;
                str_addr  <= str_base + char_idx;
            end
            endcase
        end
        end
    end

endmodule