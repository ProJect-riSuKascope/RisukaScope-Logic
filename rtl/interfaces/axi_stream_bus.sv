/*
    axi_stream_bus.v
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
    interface axi_stream_bus(
        bit aclk,
        bit aresetn
    );

        logic [15:0] tdata;
        logic [1:0]  tstrb;
        logic [1:0]  tkeep;
        bit          tlast;
        bit          tuser;

        bit          tvalid;
        bit          tready;

        modport master(
            input  tdata,
            input  tstrb,
            input  tkeep,
            input  tlast,
            input  tuser,

            input  tvalid,
            output tready
        );

        modport slave(
            output tdata,
            output tstrb,
            output tkeep,
            output tlast,
            output tuser,

            output tvalid,
            input  tready
        );
    endinterface
endpackage