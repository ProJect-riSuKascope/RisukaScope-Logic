/*
    ahb_intf.v
    AHB interface verilog header

    Copyright 2022 Hiryuu T. (PFMRLIB)

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
    The file should be included in your module.
    Including at the end of the module is recommended, just as:

        < Other code >
        `include "ahb_intf_xxxx"        // Cutsom name of your AHB interface file
    endmodule

    The following signals are used, so you should define them at the module port.

    input  wire [31:0]     haddr_s,
    input  wire [2:0]      hburst_s,
    // Locked sequence (HMASTLOCK) is not used.
    // Protection option (HPROT[6:0]) is not used.
    input  wire [2:0]      hsize_s,
    // Secure transfer (HNONSEC) is not used.
    // Exclusive transfer (HEXCL) is not used.
    // Master identifier (HMASTER[3:0]) is not used.
    input  wire [1:0]      htrans_s,
    input  wire [31:0]     hwdata_s,
    input  wire            hwrite_s,

    output reg  [31:0]     hrdata_s,
    output reg             hreadyout_s,
    output reg             hresp_s,
    // Exlusive transfer is not available, thus HEXOKAY signal is not used.

    input  wire            hsel_s

*/
    
    // Define the name of clock, reset and clock enable signal here.
    `define AHB_CLOCK_NAME clk
    `define AHB_RESET_NAME reset_n
    `define AHB_CE_NAME    ce

    // ---------------------- Please DO NOT modify below this line ---------------------- 
    // AHB Interface
    // AHB signals
    reg  [31:0] haddr_last;
    reg         hwrite_last;
    reg  [31:0] hwdata_last;

    wire        ahb_writeable;

    // ---------------------- Please DO NOT modify above this line ---------------------- 
    task reg_read_ahb();
    begin
        /*
            Register read task. Add your registers here.
            For example:

            casex(haddr_s)
                'h0:hrdata_s <= reg_0;          // Address of reg0 is 0x0000
                'h4:hrdata_s <= reg_1;          // Address of reg1 is 0x0004
            endcase

            You can map a synchonous read/write RAM here as well.
            For example:

                'h1xxx:hrdata_s <= <memory>[haddr_s[15:0]];     // <memory> is mapped to 0x1000.
        */
        casex(haddr_s[15:2])
            'h00:data <= reg_ctrl;
            'h01:data <= reg_stat;
            'h1x:data <= prom_buff[addr[11:2]];
            'h2x:data <= sorted[addr[5:2]];
        endcase
    end
    endtask

    task reg_write_ahb();
    begin
        /*
            Register write task. it works in a similar way.
            For example:

            'h0:reg_0 <= hwdata_s;
            'h1xxx:<memory>[haddr_s[15:0]] <= hwdata_s;
        */
        casex(haddr_last[15:2])
            'h00:reg_ctrl <= data;
            'h01:reg_stat <= data;
            // The buffers are not available to write.
        endcase
    end
    endtask

    assign ahb_writeable = 1'b1;

    task reg_reset_ahb();
    begin
        /*
            Register reset task.
            Examples:

            'h0:reg_0 <= 'h0;

            Note: Don't reset a large memory block.
                  The large memory block should be synthized into a BRAM, which can't be reseted;
                  A large memory block with a reset will be synthized into a SSRAM composing by
                  lots of registers and LUTs.
        */
        reg_ctrl <= 0;
        reg_stat <= 0;
    end
    endtask

    task reg_update_ahb();
    begin
        /*
            Register field update task.
            The register fields should be updated here.
            For example:
                Assuming that status register, reg_stat, has a field reg_stat[1] which indicates the routine is done.

                if(<DONE_CONDITION>)
                    reg_stat[1] <= 1'b1;
        */
        target[1] <= (stat == STAT_DONE);
    end
    endtask

    // ---------------------- Please DO NOT modify below this line ---------------------- 

    // AHB FSM
    localparam  AHB_IDLE  = 2'b00;
    localparam  AHB_READ  = 2'b01;
    localparam  AHB_WRITE = 2'b10;
    localparam  AHB_ERROR = 2'b11;
    
    reg  [1:0]  ahb_stat;

    task ahb_transcation();
    begin
        if(hwrite_s)
            ahb_stat <= AHB_WRITE;
        else begin
            // Fetch data from read buffer
            if((haddr_last == haddr_s) && ahb_writeable)
                hrdata_s <= hwdata_s;
            else
                reg_read_ahb();

            ahb_stat <= AHB_READ;
        end

        // Record last address and data
        haddr_last  <= haddr_s;
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
                    if(hsel_s) begin
                        ahb_transcation();
                    end
                    else begin
                        ahb_stat <= AHB_IDLE;
                        reg_update_ahb();
                    end
                end
                AHB_WRITE:begin
                    if(hsel_s) begin
                        reg_write_ahb();
                        ahb_transcation();
                    end
                    else
                        ahb_stat <= AHB_IDLE;
                end
                AHB_ERROR:begin
                    ahb_stat <= AHB_IDLE;
                end
            endcase
        end
    end
    end

    always @(*) begin
        case(ahb_stat)
            AHB_IDLE, AHB_READ:begin
                hreadyout_s = 1'b1;
                hresp_s     = 1'b0;
            end
            AHB_WRITE:begin
                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;
            end
            AHB_ERROR:begin
                // Error stage 1
                hresp_s     = 1'b1;
                hreadyout_s = 1'b0;
            end
            default:begin
                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;
            end
        endcase
    end