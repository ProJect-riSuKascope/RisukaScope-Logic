/*
    axis_monitor.sv
    AXI-Stream bus monitor

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
`include "uvm_macros.svh"

import internal_bus::*
import uvm_pkg::*

class axis_monitor extends uvm_monitor;
    virtual axis_if axis_if;
    uvm_analysis_port #(axis_item) mon_ap;

    `uvm_component_utils(axis_monitor);

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon_ap = new ("mon_ap", this);

        if(!uvm_config_db #(virtual axis_if)::get(this, "", "axis_if", axis_if))
            `uvm_fatal("AXIS interface instance not exist:", get_full_name());
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Create packet
        axis_item it = axis_item::type_id::create("axis_item", this);

        @(posedge axis_if.aclk) begin
            if(axis_if.tvalid && axis_if.tready) begin
                it.tdata <= mif.tdata;
                it.tstrb <= mif.tstrb;
                it.tkeep <= 2'b11;
                it.tlast <= mif.tlast;
                it.tuser <= mif.tuser;
    
                it.tvalid <= mif.tvalid;
            end

            mon_ap.write(it);
        end
    endtask
endclass