
/**********************************************************************************************************************************
* File Name:     driver.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Driver APB request  to APB master interface.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef _INCL_DRIVER
`define _INCL_DRIVER

`include  "definition.sv"
`include  "master_if.sv"
`include  "master_transaction.sv"
`include  "uvm_pkg.sv"

import  uvm_pkg::*;


class apb_driver  extends  uvm_driver #(master_transaction);


    `uvm_component_utils(apb_driver)

    VTSB_MASTER_T tsb_master_if;
    
    
    function new (string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction // new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(VTSB_MASTER_T)::get(this, "", "vif", vif))
            `uvm_fatal("my_driver", "virtual interface must be set for vif!!!")
   endfunction

   extern task main_phase(uvm_phase phase);
   extern task drive_one_pkt(master_transaction tr);


endclass //driver


task  apb_driver::main_phase(uvm_phase phase);

    // wait system reset end
    while(!vif.rst_n)
        @(posedge vif.clk);

    while(1) begin
        seq_item_port.get_next_item(req);
        drive_one_pkt(req);
        seq_item_port.item_done();
    end

endtask



task  apb_driver::drive_one_pkt(master_transaction tr)

    




endtask



    task run();

    int unsigned req_num = 0;
    apb_req new_req;

    forever begin
        mbx.peek(new_req);
        send(new_req);

        if (new_req.valid)
            wait_trans(new_req);
        else begin
            new_req.master_error = 0;
        end
            
        
        $display("apb_req id: %d  valid: %d  sels:%d  other_error:%d  master_error: %d\n", req_num, new_req.valid,
                        new_req.sel_id, new_req.other_error,  new_req.master_error);

        foreach (cbsq[i]) begin
	        cbsq[i].call_func(this, new_req);
	    end

        req_num++;
        tsb_master_if.sb.valid <= 0;        // set valid  zero to aviod other apb master if transferring data
        mbx.get(new_req);       
        repeat(4) @(tsb_master_if.sb);      //make sure last tsb_master_if.sb.other_error assignment completed
        new_req.master_error = 0;
        rst_tsb_if();
        repeat(2) @(tsb_master_if.sb);      // delay 2 cycle
        ->driver_2_req;
    end

    endtask


    task send(input apb_req new_req);

        tsb_master_if.sb.addr <= new_req.addr;
        tsb_master_if.sb.prot <= new_req.prot;
        tsb_master_if.sb.sels <= new_req.sel_id;
        tsb_master_if.sb.strb <= new_req.strb;
        tsb_master_if.sb.valid <= new_req.valid;

        tsb_master_if.sb.write <= new_req.write;
        if (new_req.write)
            tsb_master_if.sb.wdata <= new_req.wdata;


        if (!new_req.other_error)
            tsb_master_if.sb.other_error <= 0;
        else if (new_req.other_error == 1)
            tsb_master_if.sb.other_error <= 1;
        else
            tsb_master_if.sb.other_error <= ##(new_req.other_error - 1) 1;

    endtask


    task wait_trans(input apb_req new_req);

        wait( tsb_master_if.sb.ready);
        
        new_req.rdata = tsb_master_if.sb.rdata;
        new_req.master_error = tsb_master_if.sb.master_error;

    endtask

    task  rst_tsb_if();
        tsb_master_if.sb.valid <= 0;
        tsb_master_if.sb.other_error <= 0;
        tsb_master_if.sb.sels <= 0;
    endtask


`endif

