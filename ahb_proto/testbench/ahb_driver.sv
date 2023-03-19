
/********************************************************************************************
* File Name:     driver.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Driver AHB request  to AHB master interface.
*
*
* Version:         0.1
**********************************************************************************************/


`ifndef  AHB_DRIVER_SV
`define  AHB_DRIVER_SV

`include  "definition.sv"
`include  "master_if.sv"
`include  "ahb_master_transaction.sv"
`include  "uvm_macros.svh"


import  uvm_pkg::*;


class ahb_driver extends uvm_driver #(ahb_master_transaction);

   `uvm_component_utils(ahb_driver)
    
    VTSB_MASTER_IF  vif;

    local bit [1:0] trans_wait;

    function  new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name , parent);
        `uvm_info("ahb_driver", "new is called", UVM_HIGH);
    endfunction

   virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(VTSB_MASTER_IF)::get(this, "", "vif", vif))
            `uvm_fatal("ahb_driver", "virtual interface must be set for vif!!!")
   endfunction

    extern  task  main_phase(uvm_phase phase);
    extern  task  drive_one_pkt(ahb_master_transaction tr);
    extern  function  void set_address(ahb_master_transaction tr);
    extern  task  data_transfer(ahb_master_transaction tr);
    extern  function  reset_master_if();

endclass



function  void  ahb_driver::set_address(ahb_master_transaction tr);

    vif.addr                <=  tr.addr;
    vif.burst               <=  tr.burst;

    if (tr.delay ==  1)
        vif.delay           <=  1;
    else if(!tr.delay)
        vif.delay           <=  0;
    else
        vif.delay           <=  repeat(tr.delay - 1) @(posedge vif.clk) 1;

    vif.delay               <=  repeat(tr.delay + 2) @(posedge vif.clk) 0;

    if (tr.other_error == 1)
        vif.other_error         <=   1;
    else if (!tr.other_error)
        vif.other_error         <=   0;
    else
        vif.other_error         <=  repeat(tr.other_error - 1) @(posedge vif.clk) 1;
    

    if (tr.sel ==  1)
        vif.sel         <=    1;
    else  if(!tr.sel)
        vif.sel         <=    0;
    else begin
        vif.sel         <=    1;
        vif.sel         <=    repeat(tr.other_error - 1) @(posedge vif.clk) 0;
    end
    


    if (tr.valid == 1)
        vif.valid         <=  1;
    else  if(!tr.valid)
        vif.valid         <=  0;
    else begin
        vif.valid         <=  1;
        vif.valid         <=  repeat(tr.valid - 1) @(posedge vif.clk) 0;
    end
        
    

    `ifdef  AHB_PROT
        vif.prot           <=  tr.prot;
    `endif
    `ifdef  AHB_WSTRB
        vif.strb           <=  tr.strb;
    `endif

    vif.size           <=  tr.size;
    vif.write          <=  tr.write;

endfunction



task  ahb_driver::data_transfer(ahb_master_transaction tr);

    int unsigned  len =  ahb_pkg::get_burst_len(tr.burst);
    len = len?len:  tr.data_size;


    if (tr.write)begin
        vif.wdata    <=  tr.write? tr.wdata[0]:  0;        
        trans_wait++;
    end


    if ( len == 1 )
        return;


    for (int i = 1;  i < len; i++) begin
        wait(!trans_wait[1] || vif.ready);
        @(posedge vif.clk);
        if (tr.write )
            vif.wdata    <=  !vif.master_error && !vif.other_error ? tr.wdata[i]: 0;

        trans_wait++;

        if (!trans_wait[1])
            continue;

        wait( vif.ready == 1'd1);
        @(posedge vif.clk);
        if (vif.master_error || vif.other_error || !vif.sel  || !vif.valid)
                break;
        trans_wait--;
    end

endtask


function  ahb_driver::reset_master_if();

    vif.addr                <=    0;
    vif.burst               <=    0;
    vif.delay               <=    0;
    vif.other_error         <=    0;

    `ifdef  AHB_PROT
        vif.prot            <=    0;
    `endif
    `ifdef  AHB_WSTRB
        vif.strb            <=    0;
    `endif

    vif.sel                 <=    0;
    vif.size                <=    0;
    vif.valid               <=    0;
    vif.write               <=    0;

endfunction


task ahb_driver::main_phase(uvm_phase phase);

    `uvm_info("ahb_driver", "main_phase is called", UVM_HIGH);

    while(1) begin
        seq_item_port.get_next_item(req);
        drive_one_pkt(req);
        seq_item_port.item_done();
    end

    repeat(6) @(posedge vif.clk);

endtask


task  ahb_driver::drive_one_pkt(ahb_master_transaction tr);

    int unsigned  len = ahb_pkg::get_burst_len(tr.burst);
    len = len?len:  tr.data_size;

    wait( !trans_wait[1] || !vif.busy  );
    @( posedge vif.clk);

    set_address(tr);

    if (!tr.sel || !tr.valid )
        return;

    data_transfer(tr);

    if (len == 1) return;

    @(posedge vif.clk);


    vif.valid        <=   0;
    repeat(6)  @(posedge vif.clk);

    reset_master_if();
    trans_wait    =   0;

   `uvm_info("ahb_driver", "end drive one pkt", UVM_HIGH);

endtask


`endif

