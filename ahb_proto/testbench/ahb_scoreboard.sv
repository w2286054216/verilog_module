
/*********************************************************************************************************
* File Name:     environment.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Testbench environment for APB mater interface and APB slave interfaces.
*
*
* Version:         0.1
********************************************************************************************************/


`ifndef  AHB_ENV_SV
`define  AHB_ENV_SV

`include  "definition.sv"
`include  "ahb_transaction.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;


class ahb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(my_scoreboard)

    ahb_transaction  master_queue[$];
    ahb_transaction  slave_queue[$];
    ahb_transaction  invalid_queue[$];

    uvm_blocking_get_port #(ahb_transaction)  exp_port;
    uvm_blocking_get_port #(ahb_transaction)  act_port;


    function new(string name = "ahb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    function  build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_port = new("exp_port", this);
        act_port = new("act_port", this);
    endfunction

    extern virtual task main_phase(uvm_phase phase);

endclass

task  ahb_scoreboard::main_phase(uvm_phase phase);


endtask


`endif

