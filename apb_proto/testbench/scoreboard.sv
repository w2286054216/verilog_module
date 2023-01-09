

/**********************************************************************************************************************************
* File Name:     scoreboard.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Save APB request and APB slave response.
*
*
* Version:         0.1
*********************************************************************************************************************************/



`ifndef  _INCL_SCOREBOARD
`define  _INCL_SCOREBOARD


`include "definition.sv"




class Scoreboard;
   
   tsb_apb_req setup_failed[$];
   tsb_apb_req setup[$];
   tsb_apb_resp  resps[$];

   int  unsigned correct_setup, correct_setup_failed;
   
   function new();
      this.correct_setup = 0;
      this.correct_setup_failed = 0;
   endfunction

   function  void save_apb_req(input tsb_apb_req new_req);
     if (!new_req.valid  || (new_req.valid && ( (new_req.sel_id > `APB_SLAVE_DEVICES) || 
            !new_req.sel_id || (new_req.other_error == 1) )))
            setup_failed.push_back(new_req);
      else
            setup.push_back(new_req);

   endfunction

   function  void save_apb_resp(input tsb_apb_resp new_resp);
         resps.push_back(new_resp);
   endfunction


   function void  wrap_up();

      foreach(setup_failed[i])begin
            
            if (!setup_failed[i].valid && setup_failed[i].master_error)
                  continue;
            if (setup_failed[i].valid && !setup_failed[i].master_error)
                  continue;

            correct_setup_failed++;
      end

      $display("setup failed: %d  setup: %d  resp: %d\n", setup_failed.size, setup.size, resps.size);

      if (setup.size != resps.size) begin
            $display("apb_req not equal resps\n");
            return;
      end

      foreach(setup[i]) begin
            int unsigned j = i;
            if ((setup[i].addr != resps[i].addr) || (setup[i].write != resps[i].write) || (setup[i].prot != resps[i].prot)
            || (setup[i].strb != resps[i].strb) || (setup[i].sel_id != resps[i].monitor_id) )
                  continue;

            if (setup[i].write &&  !setup[i].other_error && !resps[i].other_error  && (setup[i].wdata != resps[i].wdata) )
                  continue;

            if (!setup[i].write && !setup[i].other_error && !resps[i].other_error && (setup[i].rdata != resps[i].rdata) )
                  continue;

            if (!setup[i].other_error && !resps[i].other_error && ( setup[i].master_error || resps[i].slave_error ))
                  continue;


            if ( setup[i].other_error && (setup[i].other_error < (resps[i].other_ready + 1)) && !resps[i].slave_error)
                  continue;

            if ( setup[i].other_error && !resps[i].other_error && (setup[i].other_error > (resps[i].other_ready + 1) )
                              && resps[i].slave_error)
                  continue;


            if ( resps[i].other_error &&  !setup[i].master_error)
                  continue;

            correct_setup++;

      end
      

      $display("correct setup failed: %d  correct setup: %d\n", this.correct_setup_failed, this.correct_setup);

      
   endfunction


endclass


`endif

