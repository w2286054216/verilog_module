
/******************************************************************************************
* File Name:     apb_driver.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Driver APB request  to APB master interface.
*
*
* Version:         0.1
****************************************************************************************/


`ifndef  APB_DRIVER_SV
`define  APB_DRIVER_SV

`include  "definition.sv"
`include  "master_if.sv"
`include  "master_transaction.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;


class apb_driver  extends  uvm_driver #(master_transaction);


    `uvm_component_utils(apb_driver)

    VTSB_MASTER_IF vif;
    
    
    function new (string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction // new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(VTSB_MASTER_IF)::get(this, "", "vif", vif))
            `uvm_fatal("apb_driver", "virtual interface must be set for vif!!!")

   endfunction

   extern  task  main_phase(uvm_phase phase);
   extern  function  void  setup(master_transaction tr);
   extern  function  void  reset_if();
   extern  task  drive_one_pkt(master_transaction tr);

endclass //driver


task  apb_driver::main_phase(uvm_phase phase);

    // wait system reset end

    while(1) begin
        seq_item_port.get_next_item(req);
        drive_one_pkt(req);
        seq_item_port.item_done();
    end

endtask


function  void  apb_driver::setup(master_transaction tr);


    vif.cb.addr    <=  tr.addr;
    vif.cb.sel     <=  tr.sel;
    vif.cb.wdata   <=  tr.write ? tr.wdata: 0;
    vif.cb.write   <=  tr.write;

    `ifdef  APB_WSTRB
        vif.cb.strb     <=   tr.strb;
    `endif
    `ifdef  APB_PROT
        vif.cb.prot     <=   tr.prot;
    `endif

    if (tr.other_error == 1)
        vif.cb.other_error   <=   1;
    else if (tr.other_error)
        vif.other_error   <= #(tr.other_error - 1)   1;
    else
        vif.cb.other_error   <=   0;

endfunction


function  void  apb_driver::reset_if();

    vif.cb.addr    <=  0;
    vif.cb.sel     <=  0;
    vif.cb.wdata   <=  0;
    vif.cb.write   <=  0;

    `ifdef  APB_WSTRB
        vif.cb.strb     <=   0;
    `endif
    `ifdef  APB_PROT
        vif.cb.prot     <=   0;
    `endif

    vif.cb.other_error  <=   0;

endfunction



task  apb_driver::drive_one_pkt(master_transaction tr);

    setup(tr);

    wait(vif.cb.ready == 1'd1);

    vif.cb.sel   <=  0;

    repeat(6)  @(vif.cb);

    reset_if();

endtask




`endif

