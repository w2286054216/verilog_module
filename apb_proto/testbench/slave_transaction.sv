

/**********************************************************************
* File Name:     slave_transaction.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Slave transaction.
*
*
* Version:         0.1
**********************************************************************/

`ifndef  SLAVE_TRANSACTION_SV
`define  SLAVE_TRANSACTION_SV

`include  "definition.sv"

`include  "uvm_pkg.sv"

import  uvm_pkg::*;


class  slave_transaction  extends  uvm_sequence_item;


    rand bit [2:0] other_error;   
    rand bit [`APB_DATA_WIDTH-1:0] rdata;
    rand bit [1:0] ready;   

    constraint rdata_range { rdata[`APB_ADDR_WIDTH-1:12] == 16'h8030;}
    constraint error_ready { other_error <= (ready + 1) ;}


    `uvm_object_utils_begin(slave_transaction)
        `uvm_field_int(other_error, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(ready, UVM_ALL_ON)
    `uvm_object_utils_end


    function  new(string name = "slave_transaction");
        super.new(name);
    endfunction //new()

endclass


`endif

