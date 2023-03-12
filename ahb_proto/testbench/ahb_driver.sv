
/********************************************************************************************
* File Name:     driver.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Driver AHB request  to AHB master interface.
*
*
* Version:         0.1
**********************************************************************************************/


`ifndef  AHB_DRIVER_SV
`define  AHB_DRIVER_SV

`include  "definition.sv"
`include  "ahb_master_if.sv"
`include  "ahb_master_transaction.sv"
`include  "uvm_macros.svh"


import  uvm_pkg::*;


class ahb_driver extends uvm_driver;

   `uvm_component_utils(ahb_driver)
    
    VTSB_MASTER_IF  vif;

    local bit [1:0] trans_wait;

    function  new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name , parent);
        `uvm_info("ahb_driver", "new is called", UVM_HIGH);
    endfunction

   virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(VTSB_MASTER_IF)::get(this, "", "vif", vif))
            `uvm_fatal("ahb_driver", "virtual interface must be set for vif!!!")
   endfunction

    extern task main_phase(uvm_phase phase);
    extern task drive_one_pkt(ahb_master_transaction tr);

endclass


task ahb_driver::main_phase(uvm_phase phase);

    `uvm_info("ahb_driver", "main_phase is called", UVM_HIGH);

    while(1) begin
        seq_item_port.get_next_item(req);
        drive_one_pkt(req);
        seq_item_port.item_done();
    end

    repeat(5) @(posedge vif.clk);

endtask


task  ahb_driver::drive_one_pkt(ahb_master_transaction tr);

    vif_master.addr           <= tr.addr;
    vif_master.burst          <= tr.burst;
    vif_master.end_tran       <= tr.end_tran;    
    vif_master.other_error    <= tr.other_error;
    vif_master.prot           <= tr.prot;
    vif_master.size           <= tr.size;
    vif_master.strb           <= tr.strb;
    vif_master.valid          <= tr.valid;
    vif_master.write          <= tr.write;

    if (tr.delay) begin
        if (tr.delay == 1'd1)
            vif_master.delay  <= 1'd1;
        else
            vif_master.delay  <= #(tr.delay - 1) 1'd1;
    end

    if (tr.other_error) begin
        if (tr.other_error == 1)
            vif_master.other_error  <= 1'd1;
        else
            vif_master.other_error  <= #(tr.other_error - 1) 1'd1;
    end

    repeat(6)  @(posedge vif_master.clk);

    vif_master.delay  <= 1'd1;
    vif_master.other_error  <= 1'd1;

   `uvm_info("my_driver", "end drive one pkt", UVM_LOW);
endtask


`endif

