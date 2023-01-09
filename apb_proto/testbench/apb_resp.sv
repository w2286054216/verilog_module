

/**********************************************************************************************************************************
* File Name:     apb_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB response class.
*
*
* Version:         0.1
*********************************************************************************************************************************/



`ifndef _INCL_APB_RESP
`define _INCL_APB_RESP

`include  "definition.sv"


class  apb_resp;

    bit [`APB_ADDR_WIDTH-1:0] addr;
    rand bit [2:0] other_error;
    bit [2:0] prot;    
    rand bit [`APB_DATA_WIDTH-1:0] rdata;
    rand bit [1:0] ready;
    bit slave_error;    
    bit [(`APB_DATA_WIDTH >> 3) -1:0] strb;
    bit [`APB_DATA_WIDTH-1:0] wdata;
    bit write;

    constraint rdata_range { rdata[`APB_ADDR_WIDTH-1:12] == 16'h8030;}
    constraint error_ready { other_error <= (ready + 1) ;}


    function  new();
        this.addr = 0;
        this.slave_error = 0;
        this.prot = 0;
        this.strb = 0;
        this.wdata = 0;
        this.write = 0;

    endfunction //new()


    function  tsb_apb_resp pack_resp();
        tsb_apb_resp new_resp;
        new_resp.addr = this.addr;
        new_resp.other_error = this.other_error;
        new_resp.other_ready = this.ready;
        new_resp.prot = this.prot;
        new_resp.rdata = this.rdata;
        new_resp.slave_error = this.slave_error;
        new_resp.strb = this.strb;        
        new_resp.wdata = this.wdata;
        new_resp.write = this.write;

        return new_resp;
        
    endfunction


endclass // apb_req


`endif

