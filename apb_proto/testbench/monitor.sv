

/**********************************************************************************************************************************
* File Name:     monitor.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:        Monitor to get APB transferring data.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef _INCL_MONITOR
`define _INCL_MONITOR


`include "definition.sv"
`include "apb_resp.sv"
`include "slave_if.sv"


typedef class Monitor;


class monitor_cbs;

   virtual task  call_func(input Monitor mon,
		       input apb_resp  new_resp);
   endtask
endclass



class Monitor;
    apb_resp  new_resp;
    VTSB_SLAVE_T tsb_slave_if;
    int unsigned id;
    monitor_cbs cbsq[$];

     function  new(input VTSB_SLAVE_T slaves_if, input int unsigned idx);
        this.new_resp = new;
        this.tsb_slave_if = slaves_if;
        this.id = idx + 1;
    endfunction


    task run();
    
    forever begin

        assert(new_resp.randomize());
        wait( tsb_slave_if.sb.sel);         //wait sel valid
        setup_trans();
        trans_data();
        
        $display("monitor: %d   other_ready: %d  other_error: %d\n", id, new_resp.ready, new_resp.other_error);

        foreach (cbsq[i]) begin
	        cbsq[i].call_func(this, new_resp);
	    end

        wait(!tsb_slave_if.sb.sel);     //wait sel invalid

    end

    endtask


    function  setup_trans();

        new_resp.strb  = tsb_slave_if.sb.strb;
        new_resp.write =  tsb_slave_if.sb.write;
        new_resp.addr  = tsb_slave_if.sb.addr;
        new_resp.wdata = tsb_slave_if.sb.wdata;
        new_resp.prot  = tsb_slave_if.sb.prot;
        
    endfunction


    task trans_data();

        if (new_resp.other_error)begin
            if (new_resp.other_error == 1)
                tsb_slave_if.sb.other_error <= 1;
            else
                tsb_slave_if.sb.other_error <=  ##(new_resp.other_error -1) 1;  
        end
        else
            tsb_slave_if.sb.other_error <= 0;



        if (!new_resp.ready) begin
            tsb_slave_if.sb.rdata <= new_resp.rdata;
            tsb_slave_if.sb.ready <= 1;
        end 
        else begin
            tsb_slave_if.sb.rdata <= ##(new_resp.ready) new_resp.rdata;
            tsb_slave_if.sb.ready <= ##(new_resp.ready) 1;     
        end

        wait(tsb_slave_if.sb.slave_ready);
        new_resp.slave_error = tsb_slave_if.sb.slave_error;

        repeat(4) @(tsb_slave_if.sb);
        tsb_slave_if.sb.ready <= 0;
        tsb_slave_if.sb.other_error <= 0;
        tsb_slave_if.sb.rdata <= 0;

    endtask


endclass


`endif

