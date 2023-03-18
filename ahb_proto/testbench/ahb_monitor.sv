

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
    extern  task  master_collect_trans();
    extern  task  slave_collect_trans();
    extern  task  add_new_transaction();


endclass

task  ahb_monitor::main_phase(uvm_phase phase);

    fork
        while (1) begin
            add_new_transaction();
        end

        if (mon_master)
            master_collect_trans();
        else
            slave_collect_trans();

    join
    

endtask


task  ahb_monitor::slave_collect_trans();

    ahb_slave_transaction  s_tr;
    ahb_transaction  tr;
    int unsigned len, all_len;

    s_tr = new("s_tr");

    while (1) begin

        tr = trans_q[0];

        if (tr == null) begin
            @(posedge s_vif.clk);
            continue;
        end 

        @(posedge s_vif.clk);

        assert (s_tr.randomize());


        all_len  =  get_burst_len(tr.burst);
        all_len  =  all_len?  all_len: s_tr.size;
        len = 0;
        while(len  < all_len)begin
            
            s_vif.ready     <=    0;
            if ( s_vif.slave_error || ((tr.other_error == len) && tr.other_error) )
                break;

            for (int i = 0; i < tr.ready[len]; i++)begin
                if (tr.error[len] && (tr.error[len] == i))begin
                    s_vif.other_error      <=  1;
                    break;
                end
                @(posedge  s_vif.clk);
            end

            if (tr.write)
                tr.wdata.push_back(s_vif.wdata);

            if (s_vif.other_error  || s_vif.slave_error)
                break;

            s_vif.ready      <=   1;

            if(!tr.write) begin
                tr.rdata.push_back(s_tr.rdata[len]);
                s_vif.rdata      <=  s_tr.rdata[len];
            end

            @(posedge s_vif.clk);
            s_vif.rdata             <=  0;            
            s_vif.ready             <=  0;
            s_vif.other_error       <=   0;


        end

        ap.write(tr);
        trans_q.pop_front();

    end

endtask




task  ahb_monitor::master_collect_trans();

    ahb_transaction  tr;
    int unsigned len, all_len;

    while (1) begin

        tr = trans_q[0];

        if (tr == null) begin
            @(posedge m_vif.clk);
            continue;
        end 

        wait(m_vif.ready ==  1'd1);
        @(posedge m_vif.clk);

        if (m_vif.master_error) begin
            if (tr.write)
                tr.wdata.push_back(m_vif.wdata);

            ap.write(tr);            
            trans_q.pop_front();
        end
        else begin
            all_len  =  get_burst_len(tr.burst);
            if (tr.write)
                tr.wdata.push_back(m_vif.wdata);
            else
                tr.rdata.push_back(m_vif.rdata);


            if (all_len) begin
                len = tr.write? tr.wdata.size(): tr.rdata.size();
                if ( len == all_len ) begin
                    ap.write(tr);
                    trans_q.pop_front();
                end 
                else
                    continue;
            end
            else begin
                if (m_vif.burst != tr.burst) begin
                    ap.write(tr);
                    trans_q.pop_front();
                end
                else
                    continue;

            end

        end

    end

endtask




task  ahb_monitor::add_new_transaction();

    ahb_transaction  tr;

    if (trans_q.size() == 2)
        return;

    if (mon_master) begin
        @( m_vif.addr or m_vif.burst or m_vif.delay or m_vif.other_error
            or m_vif.size or  m_vif.write or m_vif.valid);
        @(posedge m_vif.clk);
        if ( !m_vif.addr && !m_vif.burst && !m_vif.delay && !m_vif.other_error
            && !m_vif.size && !m_vif.write  )
            return  0;
    end
    else  begin
        @(s_vif.addr or s_vif.sel or s_vif.write);
        wait(s_vif.sel == 1);
        @( posedge s_vif.clk);
        
    end

    tr = new("tr");
    trans_q.push_back(tr);

    if (mon_master) begin

        if ( !m_vif.valid ||  m_vif.other_error_in || !burst_addr_valid(m_vif.addr, m_vif.burst, m_vif.size) )
            tr.valid =  0;

        tr.addr   =  m_vif.addr;
        tr.burst  =  m_vif.burst;
        
        `ifdef  AHB_PROT
            tr.prot  =  m_vif.prot;
        `endif
        `ifdef  AHB_WSTRB
            tr.strb  =  m_vif.strb;
        `endif

        tr.size   =  m_vif.size;
        tr.write  =  m_vif.write;

    end
    else begin

        tr.valid  =  1;
        
        tr.addr   =  s_vif.addr;
        tr.burst  =  s_vif.burst;
        
        `ifdef  AHB_PROT
            tr.prot  =  s_vif.prot;
        `endif
        `ifdef  AHB_WSTRB
            tr.strb  =  s_vif.strb;
        `endif

        tr.size   =  s_vif.size;
        tr.write  =  s_vif.write;

    end

endtask


`endif

