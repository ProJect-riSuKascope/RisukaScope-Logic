/*
    axi_bus.v
    AXI Bus Interface

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

package internal_bus;
    // Parameters
    // AxSIZE
    parameter [2:0] SIZE_1B = 3'd0;
    parameter [2:0] SIZE_2B = 3'd1;
    parameter [2:0] SIZE_4B = 3'd2;
    // AxBURST
    parameter [1:0] BURST_FIXED = 2'b00;
    parameter [1:0] BURST_INCR  = 2'b01;
    parameter [1:0] BURST_WRAP  = 2'b10;
    // xRESP
    parameter [1:0] RESP_OKAY   = 2'b00;
    parameter [1:0] RESP_EXOKAY = 2'b01;
    parameter [1:0] RESP_SLVERR = 2'b10;
    parameter [1:0] RESP_DECERR = 2'b11;

    interface axi_bus(
        input  bit aclk,
        input  bit aresetn
    );

        // Signals
        // Write address
        logic  [31:0] awaddr;
        logic  [7:0]  awlen;
        logic  [2:0]  awsize;
        logic  [1:0]  awburst;
        logic         awlock;

        bit           awvalid;
        bit           awready;

        // Write data
        logic  [31:0] wdata;
        logic  [3:0]  wstrb;
        logic         wlast;
        
        bit           wvalid;
        bit           wready;

        // Write response
        logic  [1:0]  bresp;
        
        bit           bvalid;
        bit           bready;

        // Read address
        logic  [31:0] araddr;
        logic  [7:0]  arlen;
        logic  [2:0]  arsize;
        logic  [1:0]  arburst;
        logic         arlock;

        bit           arvalid;
        bit           arready;

        // Read data
        logic  [31:0] rdata;
        logic  [1:0]  rresp;
        logic         rlast;
        
        bit           wvalid;
        bit           wready;

        // Master interface
        modport master(
            // Write address
            input  awaddr,
            input  awlen,
            input  awsize,
            input  awburst,
            input  awlock,

            input  awvalid,
            output awready

            // Write data
            input  wdata,
            input  wstrb,
            input  wlast,

            input  wvalid,
            output wready,

            // Write response
            output bresp,

            output bvalid,
            input  bready,

            // Read address
            input  araddr,
            input  arlen,
            input  arsize,
            input  arburst,
            input  arlock,

            input  arvalid,
            output arready,

            // Read data
            output rdata;
            output rresp;
            output rlast;
            
            input  wvalid;
            input  wready;
        );

        // Slave interface
        modport slave(
            // Write address
            output awaddr,
            output awlen,
            output awsize,
            output awburst,
            output awlock,

            output awvalid,
            input  awready

            // Write data
            output wdata,
            output wstrb,
            output wlast,

            output wvalid,
            input  wready,

            // Write response
            input  bresp,

            input  bvalid,
            output bready,

            // Read address
            output araddr,
            output arlen,
            output arsize,
            output arburst,
            output arlock,

            output arvalid,
            input  arready,

            // Read data
            input  rdata;
            input  rresp;
            input  rlast;
            
            input  wvalid;
            output wready;
        );
    endinterface
endpackage