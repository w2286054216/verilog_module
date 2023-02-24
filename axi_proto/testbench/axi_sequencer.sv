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

`ifndef AXI_SEQUENCER_SV
`define AXI_SEQUENCER_SV

`include "axi_master_transaction.sv"
`include "axi_slave_transaction.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;


class  ahb_sequencer  extends  uvm_sequencer #(ahb_master_transition);
   
   `uvm_component_utils(my_sequencer)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction 
   
endclass


`endif

