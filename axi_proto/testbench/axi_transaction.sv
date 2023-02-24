
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

    bit [`AHB_ADDR_WIDTH-1:0] addr;
    bit [2:0] burst;
    bit [7:0] exp_transfer_times;
    bit [3:0] prot;
    bit [`AHB_DATA_WIDTH-1:0] rdata[];
    bit other_error;
    bit recv_error;
    bit [2:0] size;
    bit [(`AHB_DATA_WIDTH / 8) -1:0] strb;
    bit [7:0]  transferred_times;
    bit [`AHB_DATA_WIDTH-1:0] wdata[];
    bit write;


    `define uvm_object_utils_begin(ahb_slave_transition)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_int(exp_transfer_times, UVM_ALL_ON)
        `uvm_field_int(delay, UVM_ALL_ON)
        `uvm_field_int(prot, UVM_ALL_ON)
        `uvm_field_array_int(rdata, UVM_ALL_ON)
        `uvm_field_int(other_error, UVM_ALL_ON)
        `uvm_field_int(recv_error, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(transferred_times, UVM_ALL_ON)
        `uvm_field_array_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
    `define uvm_object_utils_end


    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction

endclass


class  ahb_transactions_queue extends uvm_transaction;


    ahb_transaction  ahb_transactions[$];

    `define uvm_object_utils_begin(ahb_slave_transition)
        `uvm_field_queue_object(ahb_trans, UVM_ALL_ON)
    `define uvm_object_utils_end

    function new(string name = "ahb_transactions_queue");
        super.new(name);
    endfunction

    function  void add_ahb_transaction(ahb_transaction ahb_trans = null);
        if (ahb_trans == null)
            return;
        ahb_transactions.push_back(ahb_trans);
    endfunction

    function ahb_transaction get_last_transaction();
        int unsigned index = ahb_transactions.size();
        if (!index)   return null;
        return  ahb_transactions[index - 1];
    endfunction

    function ahb_transaction get_last_last_transaction();
        int unsigned index = ahb_transactions.size();
        if (!index)   return null;
        return  ahb_transactions[index - 2];
    endfunction


endclass

`endif

