
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


`ifndef  AHB_SCOREBOARD_SV
`define  AHB_SCOREBOARD_SV

`include  "definition.sv"
`include  "ahb_transaction.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;


class ahb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(ahb_scoreboard)

    ahb_transaction  master_queue[$];
    ahb_transaction  slave_queue[$];
    ahb_transaction  invalid_queue[$];

    uvm_blocking_get_port #(ahb_transaction)  exp_port[`AHB_SLAVE_DEVICES];
    uvm_blocking_get_port #(ahb_transaction)  act_port;


    function new(string name = "ahb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    function  void  build_phase(uvm_phase phase);
        string  str;
        super.build_phase(phase);
        for (int i = 0;  i < `AHB_SLAVE_DEVICES; i++ ) begin
            $sformat(str, "exp_port%0d", i);
            exp_port[i] = new(str, this);
        end
        act_port = new("act_port", this);
    endfunction

    extern virtual task main_phase(uvm_phase phase);

endclass

task  ahb_scoreboard::main_phase(uvm_phase phase);
   ahb_transaction  master_trans,  slaves_recv[`AHB_SLAVE_DEVICES],  slave_trans;
   bit result;
 
   super.main_phase(phase);

    for (int i = 0; i < `AHB_SLAVE_DEVICES; i++) begin
        fork
            while (1) begin
                exp_port[i].get(slaves_recv[i]);
                slave_queue.push_back(slaves_recv[i]);
            end
        join
    end


   fork 

        while (1) begin
            act_port.get(master_trans);
            if (!master_trans.valid) begin
                invalid_queue.push_back(master_trans);
                continue;
            end

            if(slave_queue.size() > 0) begin
                slave_trans = slave_queue.pop_front();
                result =  master_trans.compare(slave_trans);
                if(result) begin 
                    `uvm_info("ahb_scoreboard", "Compare SUCCESSFULLY", UVM_LOW);
                end
                else begin
                    `uvm_error("ahb_scoreboard", "Compare FAILED");
                    $display("the slave pkt is");
                    slave_trans.print();
                    $display("the master pkt is");
                    master_trans.print();
                end
            end
            else begin
                `uvm_error("ahb_scoreboard", "Received from DUT, while Expect Queue is empty");
                $display("the unexpected  master  pkt is");
                master_trans.print();
            end 
        end
   join

endtask


`endif

