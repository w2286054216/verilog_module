
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

`ifndef AHB_AGENT_SV
`define AHB_AGENT_SV

`include  "definition.sv"
`include  "ahb_sequencer.sv"
`include  "ahb_driver.sv"
`include  "ahb_monitor.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;


class ahb_agent extends uvm_agent;

   `uvm_component_utils(ahb_agent)
    
    ahb_sequencer  sqr;
    ahb_driver     drv;
    ahb_monitor    mon;
    bit  m_agt;

    uvm_analysis_port #(ahb_transaction)  ap;
   
   
    function  new(string name = "ahb_agent", uvm_component parent = null);
        super.new(name , parent);
        `uvm_info("ahb_agent", "new is called", UVM_HIGH);
    endfunction


    function  void  build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            sqr = ahb_sequencer::type_id::create("sqr", this);
            drv = ahb_driver::type_id::create("drv", this);
        end
        mon = ahb_monitor::type_id::create("mon", this);
        mon.mon_master  =  m_agt;
        `uvm_info("ahb_agent", "build_phase is called", UVM_HIGH);
    endfunction 


    function  void  connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
        ap = mon.ap;
    endfunction



endclass


`endif


