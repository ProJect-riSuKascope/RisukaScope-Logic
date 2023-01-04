/*
    axis_item.sv
    Universal DSP testbench

    Copyright 2021-2023 Hiryuu "Concordia" T. (PFMRLIB)

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
// AXI-Stream sequence item
import uvm_pkg::*
`include "uvm_macros.svh"

// AXI-Stream master packet
class axis_item extends uvm_sequence_item;
    rand reg [15:0] tdata;
    rand reg [1:0]  tstrb;
    rand bit        tlast;
    rand bit        tuser;
    rand bit        tvalid;
    rand bit        tready;

    `uvm_object_utils_begin(axis_item)
        `uvm_field_int(tdata, UVM_ALL_ON)
        `uvm_field_int(tstrb, UVM_ALL_ON)
        `uvm_field_bit(tlast, UVM_ALL_ON)
        `uvm_field_bit(tuser, UVM_ALL_ON)
        `uvm_field_bit(tvalid, UVM_ALL_ON)
        `uvm_field_bit(tready, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axis_sequence_item");
        super.new(name)
    endfunction
endclass

// AXI-Stream slave response
class axis_resp extends uvm_sequence_item;
    rand bit tready;

    `uvm_object_utils_begin(axis_resp)
        `uvm_field_bit(tready, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axis_resp");
        super.new(name)
    endfunction
endclass