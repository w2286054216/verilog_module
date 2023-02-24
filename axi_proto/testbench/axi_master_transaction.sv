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

`ifndef  AXI_TRANSACTION_SV
`define  AXI_TRANSACTION_SV


`include "definition.sv"
`include "axi_pkg.sv"
`include "uvm_macros.svh"

import  uvm_pkg::*;
import  axi_pkg::*;


class  axi_master_transaction extends uvm_sequence_item;

    rand  bit [`AHB_ADDR_WIDTH-1:0] addr;
    rand  bit [2:0] burst;
    rand  bit [1: 0] delay;
    rand  bit end_trans;
    rand  bit [1:0] other_error;
    rand  bit [3:0] prot;
    rand  bit [2:0] size;
    rand  bit [(`AHB_DATA_WIDTH / 8) -1:0] strb;
    rand  bit valid;
    rand  bit [`AHB_DATA_WIDTH-1:0] wdata[];
    rand  bit write;

    constraint addr_range  { addr[`AHB_ADDR_WIDTH-1:12] == 20'h20380;}
    constraint wdata_range { foreach(wdata[i]) wdata[i][`AHB_DATA_WIDTH-1:12 == 20'h80340]; }
    constraint strb_range {  foreach(wdata[i])  (i < wdata.size - 1) -> (burst -> strb[i] == strb[i+1]);  }
    constraint wdata_size {  ((burst != AHB_BURST_INCR) && write) -> ((wdata.size == 16) && (!rdata.size));  }
    constraint rdata_size {  ((burst != AHB_BURST_INCR) && !write) -> (!wdata.size && (rdata.size == 16));  }
    constraint incr_wdata_size { ((burst == AHB_BURST_INCR) && write) -> ((wdata.size < 16) && wdata.size);  }
    constraint incr_rdata_size { ((burst == AHB_BURST_INCR) && !write) -> ((wdata.size < 16) && wdata.size);  }

    `define uvm_object_utils_begin(ahb_master_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_int(delay, UVM_ALL_ON)
        `uvm_field_int(end_trans, UVM_ALL_ON)
        `uvm_field_int(other_error, UVM_ALL_ON)
        `uvm_field_int(prot, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
        `uvm_field_int(valid, UVM_ALL_ON)
        `uvm_field_array_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
    `define uvm_object_utils_end


    function  new(string name = "ahb_master_transition");
        super.new(name);
    endfunction


endclass



`endif

