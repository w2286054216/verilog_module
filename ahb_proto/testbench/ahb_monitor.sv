

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


`ifndef AHB_MONITOR_SV
`define AHB_MONITOR_SV


`include  "definition.sv"
`include  "master_if.sv"
`include  "slave_if.sv"
`include  "ahb_slave_transaction.sv"
`include  "ahb_transaction.sv"
`include  "ahb_pkg.sv"
`include  "uvm_macros.svh"

import  uvm_pkg::*;

import  ahb_pkg::*;

class ahb_monitor extends uvm_monitor;

    `uvm_component_utils(ahb_monitor)

    VTSB_MASTER_IF m_vif;
    VTSB_SLAVE_IF  s_vif;

    ahb_transaction  trans_q[$];

    uvm_analysis_port #(ahb_transaction)  ap;

    bit mon_master;

    local bit[1:0] trans_unready;

    function  new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("ahb_monitor", "new is called", UVM_HIGH);
    endfunction


    virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (mon_master) begin
                if(!uvm_config_db#(VTSB_MASTER_IF)::get(this, "", "m_vif", m_vif))
                    `uvm_fatal("ahb_monitor", "virtual interface must be set for vif_master!!!")
            end 
            else begin
                if(!uvm_config_db#(VTSB_MASTER_IF)::get(this, "", "s_vif", s_vif))
                    `uvm_fatal("ahb_monitor", "virtual interface must be set for vif_slave!!!")
            end
            
            ap = new("ap", this);
    endfunction

    function  bit is_master_transfer();
        return !(!vif_master.addr && !vif_master.burst && !vif_master.prot && !vif_master.valid);
    endfunction

    extern  task  main_phase(uvm_phase phase);
    extern  task  master_collect_trans(ahb_transaction  tr);
    extern  task  slave_collect_trans(ahb_transaction  tr);
    extern  task  add_new_transaction();


endclass

task  ahb_monitor::main_phase(uvm_phase phase)

    ahb_transaction  tr;
    while (1) begin
        tr = new("tr");

        if (mon_master)
            master_collect_trans(tr);
        else
            slave_collect_trans(tr);

        ap.write(tr);

    end

endtask


task  ahb_monitor::slave_collect_trans(ahb_transaction  tr);

    int burst_size, wdata_size, rdata_size;

    

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


task  ahb_monitor::add_new_transaction();

    if (trans_q.size() == 2)
        return;

    if (mon_master) begin
        @( m_vif.addr or m_vif.burst or m_vif.delay or m_vif.other_error
            or m_vif.size or  m_vif.write or m_vif.valid);
        @(posedge m_vif.clk);
        if ( (!m_vif.addr && !m_vif.burst && !m_vif.delay && !m_vif.other_error
            && !m_vif.size && !m_vif.write ) || !m_vif.valid  )
            return;
    end
    else  begin
        
    end


endtask





`endif

