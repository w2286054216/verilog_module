
/**************************************************************************************
* File Name:     ahb_trans.sv
* Author:          wuqlan
* Email:           
* Date Created:    2023/1/19
* Description:     AHB trans class.
*
*
* Version:         0.1
*****************************************************************************************/


`ifndef  AHB_TRANSACTION_SV
`define  AHB_TRANSACTION_SV

`include "definition.sv"
`include "uvm_macros.svh"

import  uvm_pkg::*;


class ahb_transaction extends uvm_transaction;

    bit  [`AHB_ADDR_WIDTH-1:0]  addr;
    bit  [2:0]  burst;
    bit  error;
    bit  [`AHB_DATA_WIDTH-1:0]  rdata[$];

    `ifdef  AHB_PROT
        bit  [3: 0]  prot;
    `endif
    `ifdef  AHB_WSTRB
        bit  [(`AHB_DATA_WIDTH / 8) - 1: 0]  strb;
    `endif

    bit  [2:0] size;
    bit  [`AHB_DATA_WIDTH-1:0] wdata[$];
    bit  write;
    bit  valid;

    `uvm_object_utils_begin(ahb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_int(error, UVM_ALL_ON)  
        `uvm_field_queue_int(rdata, UVM_ALL_ON)

        `ifdef  AHB_PROT
            `uvm_field_int(prot, UVM_ALL_ON)
        `endif
        `ifdef  AHB_WSTRB
            `uvm_field_int(strb, UVM_ALL_ON)
        `endif
        
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_queue_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(valid, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction

endclass

`endif

