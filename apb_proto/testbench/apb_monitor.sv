

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
            if(!uvm_config_db#(virtual my_if)::get(this, "", "m_vif", m_vif))
                `uvm_fatal("apb_monitor", "virtual interface must be set for m_vif!!!")
        end
        else begin
            if(!uvm_config_db#(virtual my_if)::get(this, "", "s_vif", s_vif))
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



task  apb_monitor::master_collect_pkt(apb_transaction tr, output bit valid);

    @(m_vif.sel or m_vif.addr or m_vif.write or m_vif.wdata );

    if ( !vif.addr && !vif.sel  && !vif.wdata  && !vif.write  && !vif.other_error )
        return;

    tr.addr    =  m_vif.addr;
    tr.write   =  m_vif.write;
    tr.wdata   =  m_vif.write? m_vif.wdata: 0;
    tr.vaild   =  !vif.sel || vif.other_error ?  0:  1;

    `ifdef  APB_WSTRB
        tr.strb  =  m_vif.strb;
    `endif
    `ifdef  APB_PROT
        tr.prot  =  m_vif.prot;
    `endif

    if ( !(vif.sel && vif.other_error) )
        return;
    
    wait(m_vif == 1);
    tr.rdata    =   !m_vif.write  && !m_vif.master_error ? m_vif.rdata:  0;
    tr.error    =   m_vif.master_error || m_vif.master_error;


endtask



task  apb_monitor::slave_collect_pkt(apb_transaction tr);
    slave_transaction  slave_tr;
    slave_tr  =  new("slave_tr");

    wait(s_vif.sel == 1);
    assert (slave_tr.randomize());
    
    tr.addr    =  s_vif.addr;
    tr.write   =  s_vif.write;
    tr.wdata   =  s_vif.write? s_vif.wdata: 0;
    tr.valid   =  1;

    `ifdef  APB_WSTRB
        tr.strb  =  s_vif.strb;
    `endif
    `ifdef  APB_PROT
        tr.prot  =  s_vif.prot;
    `endif


    if (slave_tr.ready) begin
        s_vif.rdata           <=   #(slave_tr.ready) 1;
        s_vif.ready           <=   #(slave_tr.ready) vif.write?
                                    slave_tr.rdata: 0;
    end
    else begin
        s_vif.rdata           <=   1;
        s_vif.ready           <=   vif.write? slave_tr.rdata: 0;
    end

    if (slave_tr.other_error == 1)
        s_vif.other_error     <=  1;
    else if (slave_tr.other_error)
        s_vif.other_error     <=  #(slave_tr.other_error -1) 1;
    else
        s_vif.other_error     <=  0;
    
    for (int i = 0; i < slave_tr.ready; i++) begin
        if (s_vif.slave_error || s_vif.other_error) begin
            tr.error  = 1;
            break;
        end
    end
    
    @( posedge vif.clk);

    s_vif.other_error     <=   0;
    s_vif.rdata           <=   0;
    s_vif.ready           <=   0;


endtask



`endif

