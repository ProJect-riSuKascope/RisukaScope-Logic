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
    interface axi_lite_bus(
        input  bit aclk,
        input  bit aresetn
    );

        // Signals
        // Write address
        logic  [31:0] awaddr;
        logic  [2:0]  awprot;

        bit           awvalid;
        bit           awready;

        // Write data
        logic  [31:0] wdata;
        logic  [3:0]  wstrb;
        
        bit           wvalid;
        bit           wready;

        // Write response
        logic  [1:0]  bresp;
        
        bit           bvalid;
        bit           bready;

        // Read address
        logic  [31:0] araddr;
        logic  [7:0]  arprot;

        bit           arvalid;
        bit           arready;

        // Read data
        logic  [31:0] rdata;
        logic  [1:0]  rresp;
        
        bit           rvalid;
        bit           rready;

        // Master interface
        modport master(
            // Write address
            input  awaddr,
            input  awprot,
            input  awvalid,
            output awready,

            // Write data
            input  wdata,
            input  wstrb,
            input  wvalid,
            output wready,

            // Write response
            output bresp,
            output bvalid,
            input  bready,

            // Read address
            input  araddr,
            input  arprot,
            input  arvalid,
            output arready,

            // Read data
            output rdata;
            output rresp;
            input  rvalid;
            input  rready;
        );

        // Slave interface
        modport slave(
            // Write address
            output awaddr,
            output awprot,
            output awvalid,
            input  awready

            // Write data
            output wdata,
            output wstrb,
            output wvalid,
            input  wready,

            // Write response
            input  bresp,
            input  bvalid,
            output bready,

            // Read address
            output araddr,
            output arprot,
            output arvalid,
            input  arready,

            // Read data
            input  rdata,
            input  rresp,
            input  rvalid,
            output rready
        );
    endinterface
endpackage