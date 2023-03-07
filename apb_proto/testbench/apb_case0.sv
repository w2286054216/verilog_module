
/*******************************************************************************************
* File Name:     apb_case0.sv
* Author:          wuqlan
* Email:           
* Date Created:    2023/2/28
* Description:      Generate APB request randomly and transfer APB request to driver.
*
*
* Version:         0.1
**************************************************************************************/

`ifndef  APB_CASE0_SV
`define  APB_CASE0_SV

`include  "definition.sv"
`include  "master_transaction.sv"
`include  "base_test.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;


class case0_sequence extends uvm_sequence #(master_transaction);

   `uvm_object_utils(case0_sequence)

   master_transaction  m_trans;

   function  new(string name= "case0_sequence");
      super.new(name);
   endfunction 
   
   virtual task body();
      uvm_phase starting_phase = get_starting_phase();
      if(starting_phase != null) 
         starting_phase.raise_objection(this);
      repeat (`TEST_APB_REQ) begin
         `uvm_do(m_trans)
      end
      #100;
      if(starting_phase != null) 
         starting_phase.drop_objection(this);
   endtask


endclass


class apb_case0 extends base_test;

   `uvm_component_utils(apb_case0)

   function new(string name = "apb_case0", uvm_component parent = null);
      super.new(name,parent);
   endfunction 
   extern virtual function void build_phase(uvm_phase phase); 

endclass


function void apb_case0::build_phase(uvm_phase phase);
   super.build_phase(phase);

   uvm_config_db#(uvm_object_wrapper)::set(this, 
                                           "env.m_agt.sqr.main_phase", 
                                           "default_sequence", 
                                           case0_sequence::type_id::get());
endfunction

`endif


