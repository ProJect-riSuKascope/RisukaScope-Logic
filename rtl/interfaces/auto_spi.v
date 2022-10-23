/*
    auto_spi.v
    Automated SPI interface

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
module auto_spi(
    input  wire clk,
    input  wire reset_n,
    input  wire ce,

    // SPI Output
    output wire       sclk,
    input  wire       miso,
    output reg        mosi,
    output reg        ss,

    // Reduced native automated control interface
    input  wire [7:0]  naddr,
    output reg  [31:0] nwdata,
    output reg  [31:0] nrdata,
    input  wire        nwrite,
    input  wire        nuser,
    input  wire        nvalid,
    output wire        nready,

    // AHB Control Interface
    // Master signals
    input  wire [31:0] haddr,
    input  wire [2:0]  hburst,
    // HMASTLOCK: Not used
    input  wire [3:0]  hprot,
    input  wire [2:0]  hsize,
    // HNONSEC: Not used
    // HEXCL: Not used
    // HMASTER: Not used
    input  wire [1:0]  htrans,
    input  wire [31:0] hwdata,
    input  wire        hwrite,

    // Slave signals
    output reg  [31:0] hrdata,
    output reg         hreadyout,
    output reg         hresp,
    // HEXOKAY: Not used

    // Decoder signals
    input  wire        hsel,

    // Interrupts
    output wire        interrupt
);

    // Registers
    reg  [31:0] reg_ctrl;
    reg  [31:0] reg_stat;
    reg  [31:0] reg_prec;
    reg  [31:0] reg_fifo_addr;
    reg  [31:0] reg_ctrl_aux;

    // Buffers
    reg  [31:0] tx_fifo[0:7];
    reg  [31:0] rx_fifo[0:7];

    // AHB Interface
    // Register mapping for AHB Interface
    task reg_read_ahb(
        input  [15:0] addr,
        output [31:0] data
    );
    begin
        casex(addr[15:2])
            'h01:data <= reg_ctrl;
            'h02:data <= reg_stat;
            'h03:data <= reg_prec;
            'h1x:data <= rx_fifo[addr[5:2]];       // RX FIFO
        endcase
    end
    endtask

    task reg_write_ahb(
        input  [15:0] addr,
        input  [31:0] data
    );
    begin
        casex(addr[15:2])
            'h01:reg_ctrl           <= data;
            'h02:reg_stat           <= data;
            'h03:reg_prec           <= data;
            'h2x:tx_fifo[addr[5:2]] <= data;
        endcase
    end
    endtask

    reg  [31:0] haddr_last;
    reg         hwrite_last;
    reg  [31:0] hwdata_last;

    // AHB FSM
    localparam  AHB_IDLE  = 2'b00;
    localparam  AHB_READ  = 2'b01;
    localparam  AHB_WRITE = 2'b10;
    
    reg  [1:0]  ahb_stat;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            ahb_stat <= AHB_IDLE;
        end
        else begin
        if(ce) begin
            if(hsel) begin
                case(ahb_stat)
                AHB_IDLE, AHB_READ:begin
                    // Nothing to do
                end
                AHB_WRITE:begin
                    // Write to register
                    reg_write_ahb(haddr_last, hwdata_last);
                end
                endcase

                if(hwrite) begin
                    // Record data and address for write access
                    haddr_last  <= haddr;
                    hwrite_last <= hwrite;
                    hwdata_last <= hwdata;

                    ahb_stat <= AHB_WRITE;
                end
                else begin
                    // Fetch data from read buffer
                    reg_read_ahb(haddr, hrdata);
                    ahb_stat <= AHB_READ;
                end
            end
            else begin
                // Reset AHB FSM
                ahb_stat <= AHB_IDLE;
            end
        end
    end
    end

    // Reduced AXI (Native) interface for automatic control
    // Register mapping for native Interface
    task reg_read_nat(
        input  [15:0] addr,
        output [31:0] data
    );
    begin
        casex(addr[15:2])
            'h01:data <= reg_ctrl_aux;
            'h1x:data <= rx_fifo[addr[5:2]];
        endcase
    end
    endtask

    task reg_write_nat(
        input  [15:0] addr,
        input  [31:0] data
    );
    begin
        casex(addr[15:2])
            'h01:reg_ctrl_aux       <= data;
            'h2x:tx_fifo[addr[5:2]] <= data;
        endcase
    end
    endtask

    // Native interface FSM
    localparam NAT_IDLE = 2'b00;        // Idle, write
    localparam NAT_READ = 2'b01;

    reg [1:0] nat_stat;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            nat_stat <= NAT_IDLE;
        end
        else begin
        if(ce) begin
            case(nat_stat)
            NAT_IDLE:begin
                if(nwrite & nvalid & nready)
                    reg_write_nat(naddr, nwdata);
                else begin
                    if(nvalid) begin
                        reg_read_nat(naddr, nrdata);
                        nat_stat <= NAT_READ;
                    end
                end
            end
            NAT_READ:begin
                if(nvalid && nready)
                    nat_stat <= NAT_IDLE;
            end
            endcase
        end
        end
    end

    // Ready control
    // Delay a cycle at read access. Auto-update is not available when AHB access is in process.
    assign nready = (~((~nwrite) & (nat_stat == NAT_IDLE))) & (ahb_stat == AHB_IDLE);

    // SPI
    // SPI Control Flags
    wire [4:0]  spi_bits_word     = reg_ctrl[12:8];
    wire [4:0]  spi_word_interval = reg_ctrl[23:16];
    wire [2:0]  spi_words         = reg_ctrl[28:26];
    wire        spi_auto_enable   = reg_ctrl[3];
    wire        spi_start         = reg_ctrl[1];
    wire [15:0] spi_prec_cycles   = reg_prec[15:0];

    // SPI FSM
    localparam SPI_IDLE = 3'd0;
    localparam SPI_BIT  = 3'd1;
    localparam SPI_NEXT = 3'd2;
    localparam SPI_WAIT = 3'd3;
    localparam SPI_DONE = 3'd4;

    reg  [2:0]  spi_stat;
    reg  [4:0]  bit_count;
    reg  [2:0]  word_count;
    reg  [15:0] prec_count;
    reg  [4:0]  wait_count;

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            spi_stat <= SPI_IDLE;

            mosi <= 1'b0;
            ss   <= 1'b0;

            bit_count  <= 5'd0;
            word_count <= 3'd0;
            prec_count <= 15'd0;
            wait_count <= 5'd0;
        end
        else begin
        if(ce) begin
            case(spi_stat)
            SPI_IDLE:begin
                if(spi_start || nuser) begin
                    spi_stat <= SPI_BIT;

                    bit_count  <= spi_bits_word;
                    word_count <= spi_words;
                    prec_count <= spi_prec_cycles;
                end
            end
            SPI_BIT:begin
                if(prec_count == 0) begin 
                    if(bit_count == 0)
                        spi_stat <= SPI_NEXT;
                    else
                        bit_count = bit_count - 1;

                    mosi <= tx_fifo[word_count][bit_count];
                    rx_fifo[word_count][bit_count] <= miso;
                end
                else
                    prec_count = prec_count - 1;
            end
            SPI_NEXT:begin
                if(word_count == 0) begin
                    spi_stat   <= SPI_DONE;
                end
                else begin
                    bit_count  <= spi_bits_word;
                    word_count <= word_count - 1;

                    spi_stat   <= SPI_WAIT;
                end
            end
            SPI_WAIT:begin
                if(spi_word_interval == 0)
                    spi_stat <= SPI_BIT;
                else begin
                    if(prec_count == 0) begin 
                        if(wait_count == 0)
                            spi_stat <= SPI_BIT;
                        else
                            wait_count = wait_count - 1;
                    end
                    else
                        prec_count = prec_count - 1;
                end
            end
            SPI_DONE:begin
                spi_stat <= SPI_IDLE;
            end
            endcase
        end
        end
    end

    // SPI clock output
    assign sclk = prec_count > {1'b0, prec_count[15:1]};

    // Status update
    always @(posedge clk) begin
        if((!(nwrite & nvalid & nready)) && (!hsel)) begin
            if(!(spi_stat == SPI_IDLE))
                reg_stat[0] <= 1'b1;    // SPI busy flag

            if(spi_stat == SPI_DONE)
                reg_stat[1] <= 1'b1;    // SPI done flag
        end
    end

    // Interrupt
    assign interrupt = reg_ctrl[2] && (spi_stat == SPI_DONE);
endmodule