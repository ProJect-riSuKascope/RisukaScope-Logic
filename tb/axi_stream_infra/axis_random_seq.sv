/*
    axis_random_seq.sv
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

class axis_random_seq extends uvm_sequence#(axis_item);
    `uvm_object_utils(base_sequence)
    `uvm_declare_p_sequencer(axis_random_seq)

    axis_item it;
    int ITEM_COUNT = 1024;

    function new();
        super.new(string name, uvm_component parent);
    endfunction

    virtual task pre_body();
        // Create an instance
        if(starting_phase != null)
            starting_phase.raise_objection(this);
    endtask

    virtual task post_body();
        // Drop an instance
        if(starting_phase != null)
            starting_phase.drop_objection(this);
    endtask

    virtual task body();
        item = axis_item::type_id::create();

        repeat(ITEM_COUNT) begin
            start_item(axis_item);
            assert(axis_item.randomize());
            finish_item(axis_item);
        end
    endtask
endclass