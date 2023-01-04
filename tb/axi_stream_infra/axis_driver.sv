/*
    axis_driver.sv
    Master driver of AXI-Stream bus

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

class axis_driver_m extends uvm_driver #(axis_item);
    virtual axis_bus.master mif;

    `uvm_component_utils(axis_driver_m)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the instance from UVM config database
        if(uvm_config_db()#(virtual axis_bus.master)::get(this, "", "stream_master_dut", mif))
            `uvm_fatal("AXIS interface instance not exist:", get_full_name());
    endfunction

    virtual task run_phase(uvm_phase phase);
        axis_item it;
        super.run_phase(phase);

        forever begin
            // Get an item, drive and return finish value
            seq_item_port.get_next_item(it);
            drive(it);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive(axis_item it);
        @(posedge mif.clk) begin
            mif.tdata  <= it.tdata;
            mif.tstrb  <= it.tstrb;
            mif.tkeep  <= 2'b11;
            mif.tlast  <= it.tlast;
            mif.tuser  <= it.tuser;

            mif.tvalid <= it.tvalid;
        end

        wait(mif.tvalid && mif.tready)      // Wait for transaction finish
    endtask
endclass

class axis_driver_s extends uvm_driver #(axis_resp);
    virtual axis_bus.slave if;
    `uvm_component_utils(axis_driver_m)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the instance from UVM config database
        if(uvm_config_db()#(virtual axis_bus.slave)::get(this, "", "stream_master_dut", mif))
            `uvm_fatal("AXIS interface instance not exist:", get_full_name());
    endfunction

    virtual task run_phase(uvm_phase phase);
        axis_resp it;
        super.run_phase(phase);

        forever begin
            // Get an item, drive and return finish value
            seq_item_port.get_next_item(it);
            drive(it);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive(axis_item it);
        @(posedge mif.clk) begin
            sif.ready  <= it.tready;

        wait(mif.tvalid && mif.tready)
    endtask
endclass