/*
    agc_ahb_intf.v
    AHB interface verilog header, AGC

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
    
    // AHB Interface
    // AHB signals
    reg  [31:0] haddr_last;
    reg         hwrite_last;
    reg  [31:0] hwdata_last;

    wire        ahb_writeable;

    // ---------------------- Please DO NOT modify above this line ---------------------- 
    // Register mapping for AHB Interface
    task reg_read_ahb();
    begin
        casex(haddr_s[15:2])
            'h0:hrdata_s <= reg_ctrl;
            'h1:hrdata_s <= reg_gain_ctrl;
            'h2:hrdata_s <= reg_gain_read;
            'h3:hrdata_s <= reg_value_ctrl;
            'h4:hrdata_s <= reg_value_read;
            'h5:hrdata_s <= {16'h0, reg_hystersis};
            'h6:hrdata_s <= {16'h0, reg_step};
        endcase
    end
    endtask

    task reg_write_ahb();
    begin
        casex(haddr_last[15:2])
            'h0:reg_ctrl       <= hwdata_s;
            'h1:reg_gain_ctrl  <= hwdata_s;
            'h3:reg_value_ctrl <= hwdata_s;
            'h5:reg_hystersis  <= hwdata_s[15:0];
            'h6:reg_step       <= hwdata_s[15:0];
        endcase
    end
    endtask

    assign ahb_writeable = (haddr_s[15:2] == 16'd0) || (haddr_s[15:2] == 16'd1) || (haddr_s[15:2] == 16'd3)
                         || (haddr_s[15:2] == 16'd5) || (haddr_s[15:2] == 16'd6);

    task reg_reset_ahb();
    begin
        reg_ctrl       <= 'h0;
        reg_gain_ctrl  <= 'h0;
        reg_gain_read  <= 'h0;
        reg_value_ctrl <= 'h0;
        reg_value_read <= 'h0;
        reg_hystersis  <= 'h0;
        reg_step       <= 'h0;
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
                    else
                        ahb_stat <= AHB_IDLE;
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