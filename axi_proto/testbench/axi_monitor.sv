

/*************************************************************************
* File Name:     monitor.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:        Monitor to get APB transferring data.
*
*
* Version:         0.1
**************************************************************************/


`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV


`include  "definition.sv"
`include  "axi_master_if.sv"
`include  "axi_slave_if.sv"
`include  "axi_transaction.sv"
`include  "axi_pkg.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;

import  ahb_pkg::*;

class ahb_monitor extends uvm_monitor;

    `uvm_component_utils()

    VTSB_MASTER_T vif_master;
    VTSB_SLAVE_T  vif_slave;

    uvm_analysis_port #(ahb_transactions_queue)  ap;

    bit mon_master;

    local bit[1:0] trans_unready

    function  new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("ahb_monitor", "new is called", UVM_HIGH);
    endfunction


    virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (mon_master) begin
                if(!uvm_config_db#(VTSB_MASTER_T)::get(this, "", "vif_master", vif_master))
                    `uvm_fatal("ahb_monitor", "virtual interface must be set for vif_master!!!")
            end 
            else begin
                if(!uvm_config_db#(VTSB_MASTER_T)::get(this, "", "vif_slave", vif_slave))
                    `uvm_fatal("ahb_monitor", "virtual interface must be set for vif_slave!!!")
            end
            
            ap = new("ap", this);
    endfunction

    function  bit is_master_transfer();
        return !(!vif_master.addr && !vif_master.burst && !vif_master.prot && !vif_master.valid);
    endfunction

    extern  task  main_phase(uvm_phase phase);
    extern  function  ahb_transaction  get_ahb_transaction(ahb_transactions_queue ahb_trans_q);
    extern  function  ahb_transaction  create_ahb_transaction(ahb_transactions_queue ahb_trans_q);
    extern  function  bit  master_add_transaction(ahb_transactions_queue ahb_trans_q);
    extern  task  master_collect_trans(ahb_transactions_queue ahb_trans_q);
    extern  task  master_ready_data(ahb_transactions_queue ahb_trans_q);
    extern  function  bit  slave_add_transaction(ahb_transactions_queue ahb_trans_q);
    extern  task  slave_collect_trans(ahb_transactions_queue ahb_trans_q);
    extern  task  slave_ready_data(ahb_transactions_queue ahb_trans_q);

endclass

task  ahb_monitor::main_phase(uvm_phase phase)

    ahb_transactions_queue  ahb_trans_q;
    while (1) begin
        ahb_trans_q = new("ahb_trans_q");

        if (mon_master)
            master_collect_trans(ahb_trans_q);
        else
            slave_collect_trans(ahb_trans_q);

        ap.write(ahb_trans_q);

    end

endtask

function  ahb_transaction  ahb_monitor::get_ahb_transaction(ahb_transactions_queue ahb_trans_q);

    ahb_transaction  ahb_trans;

    ahb_trans  =  ahb_trans_q.get_last_last_transaction();

    if ( ahb_trans.exp_transfer_times == ahb_trans.transfered_times )
        return  ahb_trans_q.get_last_transaction();
    else
        return  ahb_trans;

endfunction

function  ahb_transaction  ahb_monitor::create_ahb_transaction(ahb_transactions_queue ahb_trans_q);

    ahb_transaction  ahb_trans;
    int unsigned  exp_times;

    ahb_trans  =  new("ahb_trans");

    ahb_trans.addr            =  mon_master? vif_master.addr: vif_slave.addr;
    ahb_trans.burst           =  mon_master? vif_master.burst: vif_slave.burst;
    ahb_trans.prot            =  mon_master? vif_master.prot: vif_slave.prot;
    ahb_trans.other_error     =  mon_master? vif_master.other_error: vif_slave.other_error;
    ahb_trans.size            =  mon_master? vif_master.size: vif_slave.size;
    ahb_trans.strb            =  mon_master? vif_master.strb: vif_slave.strb;
    ahb_trans.write           =  mon_master? vif_master.write: vif_slave.write;

    exp_times  =  get_burst_size(vif_master.burst);


    if (vif_master.write)begin
        ahb_trans.wdata = exp_times?new[exp_times]: new[16];
    else
        ahb_trans.rdata = exp_times?new[exp_times]: new[16];
    end

    ahb_trans.transferred_times = 0;

    ahb_trans_q.add_ahb_transaction(ahb_trans);

endfunction





task  ahb_monitor::master_ready_data(ahb_transactions_queue ahb_trans_q);

    ahb_transaction  ahb_trans;
    int unsigned exp_trans_times, transferred_times;

    ahb_trans = get_ahb_transaction(ahb_trans_q);
    ahb_trans.recv_error  =  vif_master.master_error;
    exp_trans_times =  ahb_trans.exp_transfer_times;
    transferred_times = ahb_trans.transferred_times;

    ahb_trans.transferred_times++;
    ahb_trans.recv_error = vif_master.master_error;

    if (ahb_trans.!write)begin
        fork
            @(vif_master.clk);
            ahb_trans.rdata[ahb_trans.transferred_times - 2] = vif_master.rdata;
        join_none
    end


endtask


function  bit  ahb_monitor::master_add_transaction(ahb_transactions_queue ahb_trans_q);

    ahb_transaction  ahb_trans;
    int unsigned exp_trans_times, transferred_times, last_burst;

    ahb_trans = ahb_trans_q.get_last_transaction();

    if (ahb_trans == null)   goto create_new_transaction;

    exp_trans_times =  ahb_trans.exp_transfer_times;
    transferred_times = ahb_trans.transferred_times;
    last_burst  = ahb_trans.burst;

    if ((last_burst && (exp_trans_times != (transferred_times + vif_master.ready)))
            || vif_master.master_error || ( trans_unready == 2'd2) )
        return  1'd0;

  create_new_transaction:
    ahb_trans = create_ahb_transaction(ahb_trans_q);

    return 1'd1;

endfunction




task  ahb_monitor::master_collect_trans(ahb_transactions_queue ahb_trans_q);

    int burst_size, wdata_size, rdata_size;
    bit [`AHB_DATA_WIDTH-1:0] last_wdata[$],  last_rdata[$];
    ahb_transaction ahb_trans;

    wait(is_master_transfer());

    while (1) begin

        if (!is_master_transfer())   break;

        if (vif_master.ready) begin
            master_ready_data(ahb_trans_q);
            if (trans_unready) trans_unready--;
        end

        if(master_add_transaction(ahb_trans_q))  trans_unready++;

        @(posedge vif_master.clk);

    end

endtask




task  ahb_monitor::slave_ready_data(ahb_transactions_queue ahb_trans_q);
    
    ahb_transaction  ahb_trans;
    int unsigned exp_trans_times, transferred_times;

    ahb_trans = get_ahb_transaction(ahb_trans_q);
    ahb_trans.recv_error  =  vif_slave.slave_error;
    exp_trans_times =  ahb_trans.exp_transfer_times;
    transferred_times = ahb_trans.transferred_times;

    ahb_trans.transferred_times++;
    ahb_trans.recv_error = vif_master.master_error;

    if (ahb_trans.!write)begin
        fork
            @(vif_master.clk);
            ahb_trans.rdata[ahb_trans.transferred_times - 2] = vif_master.rdata;
        join_none
    end

endtask


function  bit  ahb_monitor::slave_add_transaction(ahb_transactions_queue ahb_trans_q);

    ahb_transaction  ahb_trans;
    int unsigned exp_trans_times, transferred_times, last_burst;

    ahb_trans = ahb_trans_q.get_last_transaction();

    if (ahb_trans == null)   goto create_new_transaction;

    exp_trans_times =  ahb_trans.exp_transfer_times;
    transferred_times = ahb_trans.transferred_times;
    last_burst  = ahb_trans.burst;

    if ((last_burst && (exp_trans_times != (transferred_times + vif_master.ready)))
            || vif_master.master_error || ( trans_unready == 2'd2) )
        return  1'd0;

  create_new_transaction:
    ahb_trans = create_ahb_transaction(ahb_trans_q);

    return 1'd1;

endfunction


task  ahb_monitor::slave_collect_trans(ahb_transactions_queue ahb_trans_q);

    int burst_size, wdata_size, rdata_size;
    bit [`AHB_DATA_WIDTH-1:0] last_wdata[$],  last_rdata[$];
    ahb_transaction ahb_trans;

    wait(is_master_transfer());

    while (1) begin

        if (!is_master_transfer())   break;

        if (vif_master.ready) begin
            master_ready_data(ahb_trans_q);
            if (trans_unready) trans_unready--;
        end

        if(master_add_transaction(ahb_trans_q))  trans_unready++;

        @(posedge vif_master.clk);

    end

endtask


`endif




