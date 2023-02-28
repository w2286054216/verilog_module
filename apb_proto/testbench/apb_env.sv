
/******************************************************************************************
* File Name:     environment.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Testbench environment for APB mater interface and APB slave interfaces.
*
*
* Version:         0.1
******************************************************************************************/


`ifndef  APB_ENV_SV
`define  APB_ENV_SV

`include  "definition.sv"
`include  "master_if.sv"
`include  "slave_if.sv"
`include  "apb_agent.sv"
`include  "apb_scoreboard.sv"
`include  "apb_transaction.sv"

`include  "uvm_pkg.sv"

import  uvm_pkg::*;


class apb_env extends uvm_env;

   `uvm_component_utils(apb_env)

   apb_agent   s_agt;
   apb_agent   m_agt;
   apb_scoreboard  scb;
   
   uvm_tlm_analysis_fifo #(apb_transaction) magt_scb_fifo;
   uvm_tlm_analysis_fifo #(apb_transaction) sagt_scb_fifo;
   
   function new(string name = "apb_env", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_agt = apb_agent::type_id::create("m_agt", this);
      s_agt = apb_agent::type_id::create("s_agt", this);
      m_agt.is_active = UVM_ACTIVE;
      s_agt.is_active = UVM_PASSIVE;
      m_agt.matser_agent   =  1;
      s_agt.matser_agent   =  0;
      scb = apb_scoreboard::type_id::create("scb", this);
      magt_scb_fifo = new("magt_scb_fifo", this);
      sagt_scb_fifo = new("sagt_mdl_fifo", this);

   endfunction

   extern virtual function void connect_phase(uvm_phase phase);
   
endclass

function void apb_env::connect_phase(uvm_phase phase);
   super.connect_phase(phase);
   m_agt.ap.connect(magt_scb_fifo.analysis_export);
   scb.exp_port.connect(magt_scb_fifo.blocking_get_export);
   s_agt.ap.connect(sagt_scb_fifo.analysis_export);
   scb.act_port.connect(sagt_scb_fifo.blocking_get_export); 
endfunction


`endif


