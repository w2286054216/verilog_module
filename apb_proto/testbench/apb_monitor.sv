

/****************************************************************************
* File Name:     apb_monitor.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:        Monitor to get APB transferring data.
*
*
* Version:         0.1
***********************************************************************/


`ifndef  APB_MONITOR_SV
`define  APB_MONITOR_SV


`include  "definition.sv"
`include  "slave_transaction.sv"
`include  "slave_if.sv"
`include  "master_if.sv"
`include  "apb_transaction.sv"

`include  "uvm_macros.svh"

import  uvm_pkg::*;


class apb_monitor  extends uvm_monitor;


    `uvm_component_utils(apb_monitor)
    bit  master_mon;
    VTSB_MASTER_IF  m_vif;
    VTSB_SLAVE_IF  s_vif;

   uvm_analysis_port #(apb_transaction)  ap;
   

   function new(string name = "apb_monitor", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (master_mon) begin
            if(!uvm_config_db#(VTSB_MASTER_IF)::get(this, "", "m_vif", m_vif))
                `uvm_fatal("apb_monitor", "virtual interface must be set for m_vif!!!")
        end
        else begin
            if(!uvm_config_db#(VTSB_SLAVE_IF)::get(this, "", "s_vif", s_vif))
                `uvm_fatal("apb_monitor", "virtual interface must be set for s_vif!!!")
            
        end

        ap = new("ap", this);
   endfunction

   extern  task  main_phase(uvm_phase phase);
   extern  task  master_collect_pkt(apb_transaction tr);
   extern  task  slave_collect_pkt(apb_transaction tr);



endclass


task  apb_monitor::main_phase(uvm_phase phase);
    apb_transaction  tr;
    while(1) begin
        tr = new("tr");

        if (master_mon)
            master_collect_pkt(tr);
        else
            slave_collect_pkt(tr);

        ap.write(tr);
   end

endtask



task  apb_monitor::master_collect_pkt(apb_transaction tr);

    @(m_vif.cbm.sel or m_vif.cbm.addr or m_vif.cbm.write or m_vif.cbm.wdata );

    if ( !m_vif.cbm.addr && !m_vif.cbm.sel  && !m_vif.cbm.wdata  && 
            !m_vif.cbm.write  && !m_vif.cbm.other_error )
        return;

    tr.addr    =  m_vif.cbm.addr;
    tr.write   =  m_vif.cbm.write;
    tr.wdata   =  m_vif.cbm.write? m_vif.cbm.wdata: 0;
    tr.valid   =  !m_vif.cbm.sel || m_vif.cbm.other_error ?  0:  1;

    `ifdef  APB_WSTRB
        tr.strb  =  m_vif.cbm.strb;
    `endif
    `ifdef  APB_PROT
        tr.prot  =  m_vif.cbm.prot;
    `endif

    if ( !(m_vif.cbm.sel && !m_vif.cbm.other_error) )
        return;
    
    wait(m_vif.cbm.ready == 1);

    tr.rdata    =   !m_vif.cbm.write  && !m_vif.cbm.master_error ? m_vif.cbm.rdata:  0;
    tr.error    =   m_vif.cbm.master_error || m_vif.cbm.master_error;


endtask



task  apb_monitor::slave_collect_pkt(apb_transaction tr);
    slave_transaction  slave_tr;
    slave_tr  =  new("slave_tr");

    wait(s_vif.cb.sel == 1);
    assert (slave_tr.randomize());
    
    tr.addr    =  s_vif.cb.addr;
    tr.write   =  s_vif.cb.write;
    tr.wdata   =  s_vif.cb.write? s_vif.cb.wdata: 0;
    tr.valid   =  1;

    `ifdef  APB_WSTRB
        tr.strb  =  s_vif.cb.strb;
    `endif
    `ifdef  APB_PROT
        tr.prot  =  s_vif.cb.prot;
    `endif


    if (slave_tr.ready) begin
          s_vif.rdata  <= #(slave_tr.ready)  s_vif.cb.write?
                                      0: slave_tr.rdata;
          s_vif.ready  <= #(slave_tr.ready)  1;
    end
    else begin
        s_vif.cb.rdata           <=   s_vif.cb.write? slave_tr.rdata: 0;
        s_vif.cb.ready           <=   1;
    end

    if (slave_tr.other_error == 1)
        s_vif.cb.other_error     <=  1;
    else if (slave_tr.other_error)
        s_vif.other_error <= #(slave_tr.other_error -1)  1;
    else
        s_vif.cb.other_error     <=  0;
    
    for (int i = 0; i < slave_tr.ready; i++) begin
        @(posedge s_vif.clk);
        if (s_vif.slave_error || s_vif.other_error) begin
            tr.error  = 1;
            break;
        end
    end
    
    @( posedge s_vif.clk);

    if (tr.error) begin
        tr.rdata    =   0;
    end

    s_vif.cb.other_error     <=   0;
    s_vif.cb.rdata           <=   0;
    s_vif.cb.ready           <=   0;


endtask



`endif

