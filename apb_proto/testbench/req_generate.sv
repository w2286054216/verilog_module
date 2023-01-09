
/**********************************************************************************************************************************
* File Name:     req_generate.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Generate APB request randomly and transfer APB request to driver.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef  _INCL_REQ_GENERRATOR
`define  _INCL_REQ_GENERRATOR

`include "apb_req.sv"
`include "definition.sv"

class  req_generate;

    event  driver_2_req;
    apb_req new_req;
    mailbox #(apb_req) mbx;

    function  new(input event driver_send, input mailbox #(apb_req) mbxmbx);
        this.driver_2_req = driver_send;
        this.mbx = mbxmbx;
        new_req = new();
        
    endfunction

    task run();
        repeat(`TEST_APB_REQ) begin
        assert(this.new_req.randomize());
        this.mbx.put(new_req);
        @driver_2_req;
      end
   endtask


endclass

`endif

