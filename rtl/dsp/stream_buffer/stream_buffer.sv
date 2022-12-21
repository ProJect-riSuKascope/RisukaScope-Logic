/*
    stream_buffer.sv
    Buffer, stream input with addressable interface

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
import internal_bus::*

package dsp;
    module stream_buffer(
        input  wire clk,
        input  wire reset_n,
        input  wire ce,

        // AXI-Stream input
        axi_stream_bus axis_input(
            .aclk(clk),
            .aresetn(reset_n)
        ),

        // AXI Control Interface
        axi_lite_bus axilite_ctrl(
            .aclk(clk),
            .aresetn(reset_n)
        )
    );

        // Buffer
        reg  [15:0] buffer [0:1023];

        // Buffer write
        reg  [9:0]  idx;

        localparam STAT_IDLE  = 1'b0;
        localparam STAT_WRITE = 1'b1;
        reg  [1:0]  stat;

        always @(posedge clk, negedge reset_n) begin
            if(!reset_n) begin
                stat <= STAT_IDLE;
                idx  <= 'd0;
            end
            else begin
            if(ce) begin
                case(stat)
                STAT_IDLE:begin
                    if(axis_input.tuser) begin
                        stat <= STAT_WRITE;
                        idx  <= 'h0;
                    end
                end
                STAT_WRITE:begin
                    if(axis_input.tvalid && axis_input.tready) begin
                        buffer[idx] <= axis_input.tdata;
                        idx         <= idx + 1;

                        if(axis_input.tlast)
                            stat <= STAT_IDLE;
                    end
                end
                endcase
            end
            end
        end

        assign axis_input.tready = (stat == STAT_WRITE);

        // AXI-Lite control interface
		always @(posedge axilite_ctrl.aclk, negedge axilite_ctrl.aresetn) begin
			if(!axilite_ctrl.aresetn) begin
				axilite_ctrl.rdata  <= 32'h0;
                axilite_ctrl.rvalid <= 1'b0;
			end
			else begin
                if(axilite_ctrl.arvalid && axilite_ctrl.arready) begin
                    axilite_ctrl.rdata  <= buffer[axilite_ctrl.araddr];
                    axilite_ctrl.rvalid <= 1'b1;
                end
			end
		end

		always @(*) begin
			// Write
			axilite_ctrl.awready = 1'b0;
			axilite_ctrl.wready  = 1'b0;
			axilite_ctrl.bvalid  = 1'b0;
			axilite_ctrl.bresp   = 2'b00;

            axilite_ctrl.arready = 1'b1;
		end
	endmodule
endpackage