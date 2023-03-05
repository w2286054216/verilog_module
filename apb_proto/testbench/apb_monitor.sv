

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


    while(1) begin
        @(m_vif.sel or m_vif.addr or m_vif.write or m_vif.wdata );
        @(posedge  m_vif.clk);
        
        if ( !m_vif.addr && !m_vif.sel  && !m_vif.wdata  && 
            !m_vif.write  && !m_vif.other_error )
            continue;
        else
            break;
    end

    tr.addr    =  m_vif.addr;
    tr.write   =  m_vif.write;
    tr.wdata   =  m_vif.write? m_vif.wdata: 0;
    tr.valid   =  !m_vif.sel || m_vif.other_error ?  0:  1;

    `ifdef  APB_WSTRB
        tr.strb  =  m_vif.strb;
    `endif
    `ifdef  APB_PROT
        tr.prot  =  m_vif.prot;
    `endif

    if ( !(m_vif.sel && !m_vif.other_error) )
        return;
    
    wait(m_vif.ready == 1'd1);
    @(posedge  m_vif.clk);

    tr.rdata    =   !m_vif.write  && !m_vif.master_error ? m_vif.rdata:  0;
    tr.error    =   (m_vif.other_error && !m_vif.ready) || m_vif.master_error;

    repeat(6) @(posedge  m_vif.clk);

endtask



task  apb_monitor::slave_collect_pkt(apb_transaction tr);
    slave_transaction  slave_tr;
    slave_tr  =  new("slave_tr");

    wait(s_vif.sel == 1'd1);
    @(posedge  s_vif.clk);
    
    assert (slave_tr.randomize());

    `ifndef  APB_SLVERR
        slave_tr.other_error = 0;
    `endif


    
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
          s_vif.rdata  <= repeat(slave_tr.ready) @(posedge s_vif.clk) s_vif.write?
                                      0: slave_tr.rdata;
          s_vif.ready  <= repeat(slave_tr.ready)  @(posedge s_vif.clk)  1;
    end
    else begin
        s_vif.rdata           <=   s_vif.write? slave_tr.rdata: 0;
        s_vif.ready           <=   1;
    end

    if (slave_tr.other_error == 1)
        s_vif.other_error     <=  1;
    else if (slave_tr.other_error)
        s_vif.other_error <= repeat(slave_tr.other_error -1) @(posedge s_vif.clk) 1;
    else
        s_vif.other_error     <=  0;
    
    for (int i = 0; i < slave_tr.ready; i++) begin
        @(posedge s_vif.clk);
        if (s_vif.slave_error || s_vif.other_error || !s_vif.sel) begin
            tr.error  = 1;
            break;
        end
    end
    
    @( posedge s_vif.clk);

    if (tr.error) begin
        tr.rdata    =   0;
    end

    s_vif.other_error     <=   0;
    s_vif.rdata           <=   0;
    s_vif.ready           <=   0;

    repeat(2)  @( posedge s_vif.clk);


endtask



`endif

