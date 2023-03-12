/**************************************************************************************
* File Name:     apb_transaction.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB req class. Random AHB req.
*
*
* Version:         0.1
*************************************************************************************/

`ifndef  AHB_TRANSACTION_SV
`define  AHB_TRANSACTION_SV


`include "definition.sv"
`include "uvm_macros.svh"

import  uvm_pkg::*;
import  ahb_pkg::*;


class  ahb_master_transaction extends uvm_sequence_item;

    rand  bit  [`AHB_ADDR_WIDTH-1:0]  addr;
    rand  bit  [2: 0]  burst;
    rand  bit  [1: 0]  delay;
    rand  bit  [3: 0]  data_size;    
    rand  bit  [1: 0]  other_error;
    rand  bit  [1: 0]  sel;    
    rand  bit  [2: 0]  size;

    `ifdef  AHB_PROT
        rand  bit [3:0]   prot;
    `endif
    `ifdef  AHB_WSTRB
        rand  bit [(`AHB_DATA_WIDTH / 8) -1:0]  strb;
    `endif
    rand  bit  [1: 0]  valid;
    rand  bit  [`AHB_DATA_WIDTH-1:0] wdata[];

    rand  bit  write;

    constraint  addr_range  { addr[`AHB_ADDR_WIDTH-1:12] == 20'h20380;}
    constraint  wdata_range { foreach(wdata[i]) wdata[i][15: 0] == 16'h0340; }

    constraint  wdata_size {  write -> (wdata.size == 16);  }
    constraint  rdata_size {  !write -> (wdata.size == 0);  }


    `uvm_object_utils_begin(ahb_master_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_int(data_size, UVM_ALL_ON)        
        `uvm_field_int(delay, UVM_ALL_ON)
        `uvm_field_int(other_error, UVM_ALL_ON)
        `uvm_field_int(sel, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)

        `ifdef  AHB_PROT
            `uvm_field_int(prot, UVM_ALL_ON)
        `endif
        `ifdef  AHB_WSTRB
            `uvm_field_int(strb, UVM_ALL_ON)
        `endif

        `uvm_field_int(valid, UVM_ALL_ON)
        `uvm_field_array_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
    `uvm_object_utils_end


    function  new(string name = "ahb_master_transition");
        super.new(name);
    endfunction


endclass


`endif

