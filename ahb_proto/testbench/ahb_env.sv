
/*********************************************************************************************************
* File Name:     environment.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Testbench environment for APB mater interface and APB slave interfaces.
*
*
* Version:         0.1
********************************************************************************************************/


`ifndef  AHB_ENV_SV
`define  AHB_ENV_SV


`include  "definition.sv"
`include  "ahb_agent.sv"
`include  "ahb_transaction.sv"
`include  "ahb_scoreboard.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;


class ahb_env #(int slave_number = 4) extends uvm_env;
   
   `uvm_component_utils(ahb_env)

   ahb_agent  master_agt;
   ahb_agent  slaves_agt[slave_number];];
   ahb_scoreboard  scb;


   uvm_tlm_analysis_fifo #(ahb_transactions_queue)  master_scb_fifo;
   uvm_tlm_analysis_fifo #(ahb_transactions_queue)  slave_scb_fifos[slave_number];

   function new(string name = "my_env", uvm_component parent);
      super.new(name, parent);
      `uvm_info("ahb_env", "new is called", UVM_HIGH);
   endfunction



   virtual function void build_phase(uvm_phase phase);
         super.build_phase(phase);

         slaves_agt = new[slave_number];
         slave_agt_scb  = new[slave_number];

         master_agt = ahb_agent::type_id::create("master_agt", this);
         master_agt.is_active = UVM_ACTIVE;
         master_scb_fifo = new("master_scb_fifo", this)         

         for (int i = 0; i < slave_number ; i++) begin
            slaves_agt[i] = ahb_agent::type_id::create("slave_agt"`"i`", this);
            slaves_agt[i].is_active = UVM_PASSIVE;
            slave_scb_fifos[i] = new("slave_agt"`"i`", this);
         end

         scb = ahb_scoreboard::type_id::create("scb", this);

   endfunction


   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      master_agt.ap.connect(master_scb_fifo.analysis_export);

      for (int i = 0; i < slave_number ; i++) begin
         slave_scb_fifos[i].ap.connect(slave_scb_fifos.analysis_export);
      end


   endfunction

endclass

`endif

