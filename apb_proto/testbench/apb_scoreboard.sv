

/****************************************************************************************
* File Name:     apb_scoreboard.sv
* Author:          wuqlan
* Email:           
* Date Created:    2023/2/28
* Description:      Save APB request and APB slave response.
*
*
* Version:         0.1
****************************************************************************/

`ifndef  APB_SCOREBOARD_SV
`define  APB_SCOREBOARD_SV

`include  "definition.sv"
`include  "apb_transaction.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;


class apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_scoreboard)

    apb_transaction  invalid_queue[$];
    apb_transaction  master_queue[$];
    apb_transaction  slave_queue[$];

    uvm_blocking_get_port #(apb_transaction)  exp_port;
    uvm_blocking_get_port #(apb_transaction)  act_port;

    function  new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);

endclass 



function void apb_scoreboard::build_phase(uvm_phase phase);
   super.build_phase(phase);
   exp_port = new("exp_port", this);
   act_port = new("act_port", this);
endfunction

task  apb_scoreboard::main_phase(uvm_phase phase);
   apb_transaction  slave_recv,  master_recv, tmp_tran;
   bit result;
 
   super.main_phase(phase);
   fork 
      while (1) begin
        exp_port.get(slave_recv);
        slave_queue.push_back(slave_recv);
      end

      while (1) begin
            act_port.get(master_recv);
            if (!master_recv.valid) begin
                invalid_queue.push_back(master_recv);
                continue;
            end

            if(slave_queue.size() > 0) begin
                tmp_tran = slave_queue.pop_front();
                result = master_recv.compare(tmp_tran);

                if(result)begin
                    `uvm_info("apb_scoreboard", "Compare SUCCESSFULLY", UVM_LOW);                    
                end
                else begin
                    `uvm_error("apb_scoreboard", "Compare FAILED");
                    $display("the expect pkt is");
                    tmp_tran.print();
                    $display("the actual pkt is");
                    master_recv.print();
                end
            end
            else begin
                `uvm_error("apb_scoreboard", "Received from DUT, while Expect Queue is empty");
                $display("the unexpected pkt is");
                master_recv.print();
            end
      end
   join
endtask

`endif

