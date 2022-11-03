/*
    graphic_generator.v
    Video OSD facsimile

    Copyright 2022 Hiryuu T., Lyskamm Manufacturing

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
module graphic_generator(
    input  wire hclk,
    input  wire hresetn,
    input  wire ce,

    // AHB Control interface
    // AHB Interface
    // HCLK, HRESETn are combined into global signals.
    input  wire [31:0] haddr_s,
    input  wire [2:0]  hburst_s,
    // Locked sequence (HMASTLOCK) is not used.
    // Protection option (HPROT[6:0]) is not used.
    input  wire [2:0]  hsize_s,
    // Secure transfer (HNONSEC) is not used.
    // Exclusive transfer (HEXCL) is not used.
    // Master identifier (HMASTER[3:0]) is not used.
    input  wire [1:0]  htrans_s,
    input  wire [31:0] hwdata_s,
    input  wire        hwrite_s,

    output reg  [31:0] hrdata_s,
    output reg         hreadyout_s,
    output reg         hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire        hsel_s,

    // AXI video output
    output reg  [15:0] tdata_m,
    output reg         tlast_m,
    output reg         tuser_m,
    output reg         tvalid_m,
    input  wire        tready_m
);
    // Screen parameters
    localparam ACTIVE_HORI = 1024;
    localparam ACTIVE_VERT = 768;

    // Registers
    reg  [31:0]  reg_ctrl;

    // Instruction fetch and check
    reg  [31:0]  inst[0:511];

    wire [11:0]  inst_ar;
    reg  [7:0]   inst_r;
    reg  [11:0]  inst_aw;
    reg  [7:0]   inst_w;
    reg          inst_we;

    always @(posedge hclk, negedge hresetn) begin
        if(!hresetn) begin
            inst_r <= 8'h0;
        end
        else begin
            inst_r <= inst[inst_ar];

            if(inst_we)
                inst[inst_aw] <= inst_w;
        end
    end

    reg  [8:0]   pc;
    reg  [31:0]  word_0, word_1, word_2;
    reg  [11:0]  y;
    reg          inst_start;

    // Decode for y pos check
    wire [11:0] y0 = word_0[11:0];
    wire [11:0] y1 = word_0[23:12];
    wire [11:0] x0 = {word_1[6:0], word_0[31:27]};

    // Instruction decode and dispatch
    wire [2:0]  opcode   = word_0[16:24];       // Opcode

    // Character and box common
    wire [3:0]  fg_color = word_1[23:20];       // Foreground color
    wire [3:0]  bg_color = word_1[27:24];       // Background color
    // Character
    wire [13:0] str_addr = word_1[18:7];        // String start address
    wire [2:0]  ch_scale = word_2[1:0];         // Scale factor
    // Box
    wire [11:0] lin_w    = word_1[18:7];        // Width
    wire        lin_fill = word_1[27];          // Filled
    wire [2:0]  lin_lwid = word_1[31:28];       // Line width

    // Chart
    wire [3:0]  chart_bx = word_1[12:7];
    wire [7:0]  chart_kx = word_1[18:13];
    wire [3:0]  chart_by = word_1[24:19];
    wire [7:0]  chart_ky = word_1[30:25];
    wire        chart_ty = word_1[31];           // Chart type

    wire [15:0] color_0  = word_2[15:0];
    wire [15:0] color_1  = word_2[31:16];

    // Instruction dispatch
    wire        str_en   = (opcode == 3'b000);
    wire        lin_en   = (opcode == 3'b001);
    wire        chart_en = (opcode == 3'b010);

    // Execution units
    // Coord signals
    wire [11:0] dy = y - y0;
    wire [11:0] dx;

    // Palette
    reg  [15:0] palette[0:15];
    reg  [3:0]  palette_aw;
    reg  [15:0] palette_w;
    reg         palette_we;

    always @(posedge hclk, negedge hresetn) begin
        if(palette_we)
            palettr[palette_aw] <= palette_w;
    end

    // String buffer
    // The GowinSynthesis is quite silly here
    reg  [7:0]  str_buffer[0:2047];

    wire [11:0] str_buffer_ar;
    reg  [7:0]  str_buffer_r;
    reg  [11:0] str_buffer_aw;
    reg  [7:0]  str_buffer_w;
    reg         str_buffer_we;

    always @(posedge hclk, negedge hresetn) begin
        if(!hresetn) begin
            str_buffer_r <= 8'h0;
        end
        else begin
            str_buffer_r <= str_buffer[str_buffer_ar];

            if(str_buffer_we)
                str_buffer[str_buffer_aw] <= str_buffer_w;
        end
    end

    // String unit
    wire        str_done;
    
    wire [3:0]  pix_str_d;
    wire [11:0] pix_str_x;
    wire        pix_str_wr;

    string_unit str_inst(
        .clk(hclk),
        .reset_n(hresetn),
        
        // Parameters
        .dy        (dy),
        .base_addr (str_addr),
        .fg_color  (fg_color),
        .bg_color  (bg_color),
        .scale     (ch_scale),

        // String buffer access
        .char_addr (str_buffer_ar),
        .char_data (str_buffer_r),

        // Pixel output
        .dx        (pix_str_x),
        .pixel_sel (pix_str_d),
        .pixel_wr  (pix_str_wr),

        // Control signals
        .start (inst_start && str_en),
        .done  (str_done)
    );

    // Box unit
    wire        lin_done;

    wire [3:0]  pix_lin_d;
    wire [11:0] pix_lin_x;
    wire        pix_lin_wr;

    lin_unit lin_inst(
        .clk(hclk),
        .reset_n(hresetn),
        
        // Parameters
        .dy        (dy),
        .width     (lin_w),
        .fg_color  (fg_color),
        .bg_color  (bg_color),

        // Pixel output
        .dx        (pix_lin_x),
        .pixel_sel (pix_lin_d),
        .pixel_wr  (pix_lin_wr),

        // Control signals
        .start (inst_start && lin_en),
        .done  (lin_done)
    );

    // Chart unit
    // Chart data buffer
    // ...And also here
    reg  [7:0]  chart_buffer[0:1023];

    wire [11:0] chart_buffer_ar;
    wire [7:0]  chart_buffer_r;
    reg  [11:0] chart_buffer_aw;
    reg  [7:0]  chart_buffer_w;
    reg  [7:0]  chart_buffer_we;

    always @(posedge hclk, negedge hresetn) begin
        if(!hresetn) begin
            chart_buffer_r <= 8'h0;
        end
        else begin
            chart_buffer_r <= chart_buffer[chart_buffer_ar];

            if(chart_buffer_we)
                chart_buffer[chart_buffer_aw] <= chart_buffer_w;
        end
    end

    wire        chart_done;

    wire [15:0] pix_chart_d;
    wire [11:0] pix_chart_x;
    wire        pix_chart_wr;

    chart_unit chart_inst(
        .clk(hclk),
        .reset_n(hresetn),
        
        // Parameters
        .dy        (dy),
        .bx        (chart_bx),
        .kx        (chart_kx),
        .by        (chart_by),
        .ky        (chart_ky),
        .color_0   (color_0),
        .color_1   (color_1),
        .t         (chart_ty),

        // Pixel output
        .dx        (pix_chart_x),
        .pixel_sel (pix_chart_d),
        .pixel_wr  (pix_chart_wr),

        // Fetch data
        .data_addr (chart_buffer_ar),
        .data      (chart_buffer_r),

        // Control signals
        .start (inst_start && chart_en),
        .done  (str_done)
    );

    // Write access
    reg  [11:0] line_wr_x;
    reg         line_wr_en;
    reg  [15:0] line_wr_d;
    reg         done;

    always @(*) begin
        case (opcode)
            3'b000:begin        // String
                line_wr_x  = x0 + pix_str_x;
                line_wr_en = pix_str_wr;
                line_wr_d  = palette[pix_str_d];

                done       = str_done;
            end
            3'b001:begin        // Box
                line_wr_x  = x0 + pix_lin_x;
                line_wr_en = pix_lin_wr;
                line_wr_d  = palette[pix_lin_d];

                done       = lin_done;
            end
            3'b010:begin
                line_wr_x  = x0 + pix_chart_x;
                line_wr_en = pix_chart_wr;
                line_wr_d  = pix_chart_d;

                done       = chart_done;
            end
            default:begin
                line_wr_x  = x0;
                line_wr_en = 1'b0;
                line_wr_d  = 15'h0;

                done       = 1'b0;
            end
        endcase
    end

    // Instruction FSM
    reg  [3:0]  stat;

    localparam STAT_IDLE  = 3'b000;
    localparam STAT_FECH0 = 3'b001;
    localparam STAT_FECH1 = 3'b010;
    localparam STAT_FECH2 = 3'b011;
    localparam STAT_WAIT  = 3'b100;
    localparam STAT_WRITE = 3'b101;
    localparam STAT_START = 3'b110;

    // Line buffer
    reg  [15:0] line_buffer [0:2047];

    reg  [11:0] hori_cnt;

    always @(posedge hclk, negedge hresetn) begin
        if(!hresetn) begin
            pc <= 9'h0;
            y  <= 12'h0;

            word_0 <= 32'h0;
            word_1 <= 32'h0;
            word_2 <= 32'h0;

            hori_cnt <= 0;
        end
        else begin
            case(stat)
            STAT_IDLE:begin
                if(gen_en)
                    stat <= STAT_FECH0;
            end
            STAT_FECH0:begin
                word_0 <= inst[pc];
                pc     <= pc + 1;
                stat   <= STAT_FECH1;
            end
            STAT_FECH1:begin
                if(opcode == 3'b100) begin         // Return
                    pc     <= jmp_dest;
                    stat   <= STAT_FECH0;
                end
                else if(opcode == 3'b101) begin
                    stat   <= STAT_WRITE;
                end
                else begin
                    if((y > y0) && (y < y1)) begin      // y in range
                        word_1 <= inst[pc];
                        pc     <= pc + 1;

                        stat   <= STAT_FECH2;
                    end
                    else begin                          // y not in range
                        pc     <= pc + 2;
                        stat   <= STAT_FECH0;
                    end
                end
            end
            STAT_FECH2:begin
                word_2 <= inst[pc];
                pc     <= pc + 1;
                stat   <= STAT_START;
            end
            STAT_START:stat <= STAT_WAIT;
            STAT_WAIT:begin
                if(done) begin
                    stat     <= STAT_FECH0;
                    hori_cnt <= 0;
                end

                // Line buffer write
                if(line_wr_en)
                    line_buffer[line_wr_x] <= line_wr_d;
            end
            STAT_WRITE:begin
                if(tvalid_m && tready_m) begin
                    if(hori_cnt == ACTIVE_HORI - 1) begin
                        if(y == ACTIVE_VERT - 1)
                            y <= 0;
                        else
                            y <= y + 1;

                        stat <= STAT_FECH0;
                    end
                    else
                        hori_cnt <= hori_cnt + 1;

                    tdata_m  <= line_buffer[hori_cnt];
                end
            end
            endcase
        end
    end

    always @(*) begin
        case(stat)
        STAT_IDLE, STAT_FECH0, STAT_FECH1, STAT_FECH2:begin
            // Control
            inst_start = 1'b0;

            // AXI-Stream interface
            tlast_m    = 1'b0;
            tuser_m    = 1'b0;
            tvalid_m   = 1'b0;
        end
        STAT_START:begin
            // Control
            inst_start = 1'b1;

            // AXI-Stream interface
            tlast_m  = 1'b0;
            tuser_m  = 1'b0;
            tvalid_m = 1'b0;
        end
        STAT_WAIT:begin
            // Control
            inst_start = 1'b0;

            // AXI-Stream interface
            tlast_m  = 1'b0;
            tuser_m  = 1'b0;
            tvalid_m = 1'b0;
        end
        STAT_WRITE:begin
            // Control
            inst_start = 1'b0;

            // AXI-Stream interface
            tlast_m  = (hori_cnt == ACTIVE_HORI - 1);
            tuser_m  = (y == 0) && (hori_cnt == 0);
            tvalid_m = 1'b1;
        end
        endcase
    end

    // AHB Interface
    // AHB signals
    reg  [31:0] haddr_last;
    reg         hwrite_last;
    reg  [31:0] hwdata_last;

    reg         ahb_halt;           // Pause a transfer
    reg         ahb_end;            // End a transfer

    always @(*) begin
        case(hburst)
        3'b000:begin        // INCR
            ahb_halt = (htrans == 2'b01);       // BUSY
            ahb_end  = (htrans == 2'b00);       // IDLE
        end
        3'b001:begin        // INCR
            ahb_halt = 1'b0;                    // No halt
            ahb_end  = (htrans == 2'b01);       // BUSY
        end
        default:begin       // INCRx, WRAPx
            ahb_halt = (htrans == 2'b01);       // BUSY
            ahb_end  = (htrans == 2'b00);       // IDLE
        end
        endcase
    end

    // AHB FSM
    localparam  AHB_IDLE  = 2'b00;
    localparam  AHB_READ  = 2'b01;
    localparam  AHB_WRITE = 2'b10;
    localparam  AHB_ERROR = 2'b11;
    
    reg  [1:0]  ahb_stat;

    task ahb_transcation();
    begin
        if(!ahb_halt) begin
            if(ahb_end) begin
                ahb_stat <= AHB_IDLE;
            end
            else begin
                if(hwrite_s)
                    ahb_stat <= AHB_WRITE;
                else
                    ahb_stat <= AHB_READ;

                // Record last address and data
                haddr_last  <= haddr_s;
            end
        end
    end
    endtask

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            // Reset AHB interface
            haddr_last  <= 0;
            hrdata_s    <= 'h0;

            // Reset registers
            reg_reset_ahb();

            ahb_stat <= AHB_IDLE;
        end
        else begin
        if(ce) begin
            case(ahb_stat)
            AHB_IDLE, AHB_READ:begin
                // Nothing to do
                if(hsel_s)
                    ahb_transcation();
                else
                    ahb_stat <= AHB_IDLE;
            end
            AHB_WRITE:begin
                if(hsel_s)
                    ahb_transcation();
                else
                    ahb_stat <= AHB_IDLE;
            end
        endcase
        end
    end
    end

    always @(*) begin
        case(ahb_stat)
            AHB_IDLE, AHB_READ:begin
                // AHB Interface
                hreadyout_s = 1'b1;
                hresp_s     = 1'b0;

                // Write control
                palette_we      = 1'b0;
                inst_we         = 1'b0;
                str_buffer_we   = 1'b0;
                chart_buffer_we = 1'b0;
            end
            AHB_WRITE:begin
                // AHB Interface
                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;

                // Write control
                palette_we      = (haddr_last[15:1]  == 'h800);
                inst_we         = (haddr_last[15:11] == 'h02);
                str_buffer_we   = (haddr_last[15:11] == 'h06);
                chart_buffer_we = (haddr_last[15:11] == 'h08);
            end
            default:begin
                // AHB interface
                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;

                // Write control
                palette_we      = 1'b0;
                inst_we         = 1'b0;
                str_buffer_we   = 1'b0;
                chart_buffer_we = 1'b0;
            end
        endcase

        // Read address
        inst_ar         = haddr_s[10:2];
        str_buffer_ar   = haddr_s[11:0];
        chart_buffer_ar = haddr_s[12:1];

        // Write address
        inst_aw         = haddr_s[10:2];
        str_buffer_aw   = haddr_s[11:0];
        chart_buffer_aw = haddr_s[12:1];

        // Write data
        palette_w       = hwdata_s[3:0];
        inst_w          = hwdata_s;
        str_buffer_w    = hwdata_s[7:0];
        chart_buffer_w  = hwdata_s[15:0];

        // Read data
        case(haddr_last[15:0])
            'h0000:hrdata_s  = reg_ctrl;
            'b0001_0000_0000_000x:hrdata_s  = {28'h0, palette[haddr_last[3:0]]};
            'b0010_0xxx_xxxx_xxxx:hrdata_s  = inst_buffer_r;
            'b0011_0xxx_xxxx_xxxx:hrdata_s  = {24'h0, str_buffer_r};
            'b0100_0xxx_xxxx_xxxx:hrdata_s  = {16'h0, chart_buffer_r};
            default:hrdata_s = 0;
        endcase
    end
endmodule