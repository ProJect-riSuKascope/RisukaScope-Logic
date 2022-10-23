/*
    axi_stream_source_file.v
    AXI-Stream Data Source from File
    
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

module axi_stream_source_file #(
    parameter FILEPATH = "input.mem",
    parameter DATA_CNT = 32768,

    parameter MODE_WRAP = 0,            // In wrap mode, The pointer back to 0 if it reached the max value.

    parameter TDATA_WIDTH = 16,
    parameter ACTUAL_DW   = 16,

    parameter USE_TUSER_START = 1,
    parameter USE_TLAST = 1,
    parameter USE_TSTRB = 0

)(
    // Clock and reset
    input  wire aclk,
    input  wire aresetn,

    // AXI-Stream signals
    output reg  [TDATA_WIDTH - 1:0] tdata_m,
    output reg  [TDATA_WIDTH / 8:0] tstrb_m,
    output reg                      tlast_m,
    output reg                      tuser_m,

    output reg                      tvalid_m,
    input  wire                     tready_m,

    // Control signal
    input  wire enable,
    output reg  finish
);
    // Read data from file
    reg  [TDATA_WIDTH-1:0] data_buffer [0:65535];

    initial begin
        $readmemh(FILEPATH, data_buffer);
    end

    reg  [15:0] ptr;    // Data pointer
    always @(posedge aclk, negedge aresetn) begin
        if(!aresetn) begin
            ptr    <= 0;
            finish <= 0;

            tdata_m   <= 'h0;
            tstrb_m   <= 'h0;

            tvalid_m  <= 1'b0;
        end
        else begin
            if(tvalid_m && tready_m) begin
                tdata_m <= data_buffer[ptr];

                if(ptr == DATA_CNT - 1) begin
                    if(MODE_WRAP)       // Wrap mode
                        ptr <= 0;       // The pointer is set to 0
                    else
                        finish <= 1;    // Set finish flag
                end
                else
                    ptr <= ptr + 1;
            end

            tvalid_m <= enable;
        end
    end

    always @(*) begin
        if(USE_TUSER_START)
            tuser_m = (ptr == 0);
        else
            tuser_m = 1'b0;

        if(USE_TLAST)
            tlast_m = (ptr == DATA_CNT - 1);
        else
            tlast_m = 1'b0;
    end
endmodule