
/******************************************************************************************
* File Name:     apb_agent.sv
* Author:          wuqlan
* Email:           
* Date Created:    2023/2/28
* Description:
*
*
* Version:         0.1
****************************************************************************************/

`ifndef  APB_AGENT_SV
`define  APB_AGENT_SV

`include  "definition.sv"
`include  "apb_transaction.sv"
`include  "apb_driver.sv"
`include  "apb_monitor.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;

class apb_agent extends uvm_agent;

   `uvm_component_utils(apb_agent)

   apb_sequencer  sqr;
   apb_driver     drv;
   apb_monitor    mon;

   bit  matser_agent;
   
   uvm_analysis_port #(apb_transaction)  ap;
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction 
   
   extern virtual function void build_phase(uvm_phase phase);
   extern virtual function void connect_phase(uvm_phase phase);

endclass 


function void apb_agent::build_phase(uvm_phase phase);
   super.build_phase(phase);
   if (is_active == UVM_ACTIVE) begin
      sqr = apb_sequencer::type_id::create("sqr", this);
      drv = apb_driver::type_id::create("drv", this);
   end
   mon = apb_monitor::type_id::create("mon", this);
   mon.master_mon  =  matser_agent;
endfunction 

function void apb_agent::connect_phase(uvm_phase phase);
   super.connect_phase(phase);
   if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
   end
   ap = mon.ap;
endfunction

`endif


