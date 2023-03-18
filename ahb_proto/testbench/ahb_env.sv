
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


class ahb_env #(int unsigned slave_number = 4) extends uvm_env;
   
   `uvm_component_utils(ahb_env)

   ahb_agent  m_agt;
   ahb_agent  s_agts[slave_number];
   ahb_scoreboard  scb;


   uvm_tlm_analysis_fifo #(ahb_transaction)  magt_scb_fifo;
   uvm_tlm_analysis_fifo #(ahb_transaction)  sagts_scb_fifos[slave_number];

   function new(string name = "my_env", uvm_component parent);
      super.new(name, parent);
      `uvm_info("ahb_env", "new is called", UVM_HIGH);
   endfunction



   virtual function void build_phase(uvm_phase phase);
         super.build_phase(phase);

         s_agts = new[slave_number];
         sagts_scb_fifos  = new[slave_number];

         m_agt = ahb_agent::type_id::create("m_agt", this);
         m_agt.is_active = UVM_ACTIVE;
         m_agt.m_agt  =  1;
         magt_scb_fifo = new("magt_scb_fifo", this);        

         for (int i = 0; i < slave_number ; i++) begin
            string str;
            $sformat(str, "s_agt%d" , i);
            s_agts[i] = ahb_agent::type_id::create(str, this);
            s_agts[i].is_active = UVM_PASSIVE;
            s_agts[i].m_agt  =  0;
            $sformat(str, "sagts_scb_fifo%d", i);
            sagts_scb_fifos[i] = new(str, this);
         end

         scb = ahb_scoreboard::type_id::create("scb", this);

   endfunction


   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      m_agt.ap.connect(magt_scb_fifo.analysis_export);
      scb.act_port.connect(magt_scb_fifo.blocking_get_export);

      for (int i = 0; i < slave_number ; i++) begin
         s_agts[i].ap.connect(sagts_scb_fifos[i].analysis_export);
         scb.exp_port.connect(sagts_scb_fifos[i].blocking_get_export);
      end

   endfunction

endclass

`endif

