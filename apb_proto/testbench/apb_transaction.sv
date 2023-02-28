
/**********************************************************************
* File Name:     apb_transaction.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB transaction.
*
*
* Version:         0.1
**********************************************************************/

`ifndef  APB_TRANSACTION_SV
`define  APB_TRANSACTION_SV

`include  "definition.sv"

`include  "uvm_pkg.sv"

import  uvm_pkg::*;


class  apb_transaction  extends  uvm_sequence_item;

    bit  [`APB_ADDR_WIDTH-1:0]  addr;
    bit  error;
    bit  [`APB_DATA_WIDTH-1:0]  rdata;
    bit  valid;
    bit  [`APB_DATA_WIDTH-1:0]  wdata;
    bit  write;

    `ifdef  APB_WSTRB
        bit  [(`APB_DATA_WIDTH / 8) -1:0]  strb;
    `endif
    `ifdef  APB_PROT
        bit  [2:0]  prot;    
    `endif


    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(error, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(valid, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)

        `ifdef  APB_WSTRB
            `uvm_field_int(strb, UVM_ALL_ON)
        `endif
        `ifdef  APB_PROT
            `uvm_field_int(prot, UVM_ALL_ON)
        `endif
    `uvm_object_utils_end


    function  new(string name = "apb_transaction");
        super.new(name);
    endfunction //new()

endclass


`endif