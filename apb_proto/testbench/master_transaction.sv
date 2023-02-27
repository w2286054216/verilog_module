
/********************************************************************************
* Module Name:     master_transaction
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     master_transaction class.
*
*
* Version:         0.1
*********************************************************************************/


`ifndef  MASTER_TRANSACTION_SV
`define  MASTER_TRANSACTION_SV

`include  "definition.sv"

`include  "uvm_pkg.sv"

import  uvm_pkg::*;


class  master_transaction  extends  uvm_sequence_item;

    rand  bit  [`APB_ADDR_WIDTH-1:0] addr;
    rand  bit  [1:0]  other_error;
    rand  bit  sel;    
    rand  bit  [`APB_DATA_WIDTH-1:0]  wdata;
    rand  bit  write;

    `ifdef  APB_WSTRB
        rand  bit  [(`APB_DATA_WIDTH / 8) -1:0]  strb;
    `endif
    `ifdef  APB_PROT
        rand  bit  [2:0]  prot;    
    `endif


    constraint addr_range { addr[`APB_ADDR_WIDTH-1:12] == 20'h20380;}

    `uvm_object_utils_begin(master_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(other_error, UVM_ALL_ON)
        `uvm_field_int(sel, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)

        `ifdef  APB_WSTRB
            `uvm_field_int(strb, UVM_ALL_ON)
        `endif
        `ifdef  APB_PROT
            `uvm_field_int(prot, UVM_ALL_ON)  
        `endif
        
    `uvm_object_utils_end


    function  new(string name = "master_transaction");
        super.new(name);
    endfunction //new()


endclass

`endif

