/*
    ahb_intf_fir.v
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
    // ---------------------- Please DO NOT modify below this line ---------------------- 
    // AHB Interface
    // AHB signals
    reg         hwrite_last;
    reg  [31:0] hwdata_last;

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
        casex(haddr_last)
            'h0000:hrdata_s  = reg_ctrl;
            default:hrdata_s = reg_ctrl;
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
        casex(haddr_last[15:0])
            'h0000:reg_ctrl <= hwdata_s;
            // The buffers are written in combiational blocks
        endcase
    end
    endtask

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
        reg_ctrl <= 32'h0000_0001;
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
    end
    endtask

    // ---------------------- Please DO NOT modify below this line ---------------------- 

    wire ahb_pause = (htrans_s == 2'b00) || (htrans_s == 2'b01);

    // AHB FSM
    localparam  AHB_IDLE  = 2'b00;
    localparam  AHB_READ  = 2'b01;
    localparam  AHB_WRITE = 2'b10;
    localparam  AHB_ERROR = 2'b11;
    
    reg  [1:0]  ahb_stat;

    task ahb_transcation();
    begin
        if(!ahb_pause) begin
            if(hwrite_s)
                ahb_stat <= AHB_WRITE;
            else
                ahb_stat <= AHB_READ;

            // Record last address and data
            haddr_last  <= haddr_s[15:0];
            hwrite_last <= hwrite_s;
        end
    end
    endtask

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            // Reset AHB interface
            haddr_last  <= 0;
            hwrite_last <= 1'b0;

            // Reset registers
            reg_reset_ahb();

            ahb_stat <= AHB_IDLE;
        end
        else begin
            case(ahb_stat)
                AHB_IDLE, AHB_READ:begin
                    // Nothing to do
                    if(hsel_s)
                        ahb_transcation();

                    reg_update_ahb();
                end
                AHB_WRITE:begin
                    reg_write_ahb();
                    
                    if(hsel_s) begin
                        ahb_transcation();
                    end
                    else begin
                        ahb_stat <= AHB_IDLE;
                    end
                end
                AHB_ERROR:begin
                    ahb_stat <= AHB_IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        case(ahb_stat)
            AHB_IDLE:begin
                hrdata_s    = 0;

                hreadyout_s = 1'b1;
                hresp_s     = 1'b0;

                coeff_we = 1'b0;
            end
            AHB_READ:begin
                casex(haddr_last)
                'h0000:hrdata_s  = reg_ctrl;
                // Buffers are read-only
                default:hrdata_s = reg_ctrl;
                endcase

                hreadyout_s = 1'b1;
                hresp_s     = 1'b0;

                coeff_we = 1'b0;
            end
            AHB_WRITE:begin
                hrdata_s    = 0;

                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;

                if(ahb_pause)
                    coeff_we = 1'b0;
                else
                    coeff_we = (haddr_last[15:9] == 'b0001_01);
            end
            AHB_ERROR:begin
                hrdata_s    = 0;

                // Error stage 1
                hresp_s     = 1'b1;
                hreadyout_s = 1'b0;

                coeff_we = 1'b0;
            end
            default:begin
                hrdata_s    = 0;

                hresp_s     = 1'b0;
                hreadyout_s = 1'b1;

                coeff_we = 1'b0;
            end
        endcase
    end