
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


`ifndef DEFAULT_CASE_SV
`define DEFAULT_CASE_SV

`include  "definition.sv"
`include  "ahb_master_transaction.sv"
`include  "base_test.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;

class default_case_sequence extends uvm_sequence #(ahb_master_transaction);

   `uvm_object_utils(default_case_sequence)

   ahb_master_transaction m_trans;

   function  new(string name= "default_case_sequence");
      super.new(name);
   endfunction 
   
   virtual task body();
      uvm_phase starting_phase = get_starting_phase();
      if(starting_phase != null) 
         starting_phase.raise_objection(this);

      repeat(`AHB_TRANS_TIMES) begin
         `uvm_do(m_trans)
      end

      #1000;
      if(starting_phase != null) 
         starting_phase.drop_objection(this);
   endtask


endclass


class default_case extends base_test;

   `uvm_component_utils(default_case)

   function new(string name = "default_case", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void  build_phase(uvm_phase phase);
      super.build_phase(phase);

      uvm_config_db#(uvm_object_wrapper)::set(this, 
                                             "env.master_agt.sqr.main_phase", 
                                             "default_sequence", 
                                             default_case_sequence::type_id::get());
   endfunction


endclass


`endif

