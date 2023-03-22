
/******************************************************************************************
* File Name:     apb_sequencer.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Driver APB request  to APB master interface.
*
*
* Version:         0.1
****************************************************************************************/

`ifndef APB_SEQUENCER_SV
`define APB_SEQUENCER_SV

`include  "definition.sv"
`include  "master_transaction.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;

class apb_sequencer extends uvm_sequencer #(master_transaction);
   
   `uvm_component_utils(apb_sequencer)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction 
   
endclass

`endif


