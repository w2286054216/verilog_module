
/**********************************************************************************************************************************
* File Name:     environment.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Testbench environment for APB mater interface and APB slave interfaces.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef  _INCL_ENVIRONMENT
`define  _INCL_ENVIRONMENT

`include "definition.sv"
`include "driver.sv"
`include "master_if.sv"
`include "slave_if.sv"
`include "monitor.sv"
`include "req_generate.sv"
`include "scoreboard.sv"



class Scb_Driver_cbs extends driver_cbs;
   Scoreboard scb;

   function new(Scoreboard scb);
      this.scb = scb;
   endfunction

    virtual task  call_func(input driver drv,
		       input apb_req  new_req);
            tsb_apb_req tsb_req = new_req.pack_req;
            scb.save_apb_req(tsb_req);
   endtask
endclass


class Scb_Monitor_cbs extends monitor_cbs;
   Scoreboard scb;

   function new(Scoreboard scb);
      this.scb = scb;
   endfunction

    virtual task  call_func(input Monitor mon,
		       input apb_resp  new_resp);
            tsb_apb_resp tsb_resp = new_resp.pack_resp;
            tsb_resp.monitor_id = mon.id;
            scb.save_apb_resp(tsb_resp);
   endtask
endclass



class Environment;
   
   req_generate  req_generator;
   event drv2gen;
   mailbox #(apb_req) mbx;
   Monitor  monitors[];
   driver drv_master;
   Scoreboard scb;
   virtual master_if.TSB_MASTER  vmaster_if;
   virtual slave_if.TSB_SLAVE   vslave_ifs[];
   int unsigned slaves_number;


   function new(  input VTSB_MASTER_T vtsb_master, input VTSB_SLAVE_T vtsb_slaves[], input int  unsigned slaves);

      this.scb = new;
      this.vmaster_if =  vtsb_master;
      this.slaves_number = slaves;
      this.vslave_ifs = new[slaves];
      for (int i = 0; i < slaves;  i++) begin
         this.vslave_ifs[i] = vtsb_slaves[i];
      end

   endfunction

   virtual function void build();

   Scb_Driver_cbs driver_cbs = new(this.scb);
   Scb_Monitor_cbs monitor_cbs = new(this.scb);

   this.mbx = new;
   this.req_generator = new(this.drv2gen, this.mbx);

   this.drv_master = new(this.drv2gen, mbx, this.vmaster_if);
   this.drv_master.cbsq.push_back(driver_cbs);  

   this.monitors = new[this.slaves_number];
   for (int i = 0; i < this.slaves_number;  i++) begin
         this.monitors[i] = new(this.vslave_ifs[i], i);
         this.monitors[i].cbsq.push_back(monitor_cbs);
   end

   endfunction


   virtual task run();

   fork
      this.req_generator.run();
      this.drv_master.run();
   join_none


   foreach(this.monitors[i]) begin
      int j=i;
      fork
	      this.monitors[j].run();
      join_none
   end

   repeat (1_000) @(this.vmaster_if.sb);

   endtask


   virtual task wrap_up();
   scb.wrap_up();

   endtask



endclass


`endif

