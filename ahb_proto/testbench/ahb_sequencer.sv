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

`ifndef AHB_SEQUENCER_SV
`define AHB_SEQUENCER_SV

`include "ahb_master_transaction.sv"
`include "ahb_slave_transaction.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;


class  ahb_sequencer  extends  uvm_sequencer #(ahb_master_transaction);
   
   `uvm_component_utils(ahb_sequencer)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction 
   
endclass


`endif

