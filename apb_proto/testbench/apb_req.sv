
/**********************************************************************************************************************************
* Module Name:     apb_req
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB req class. Random APB req.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef  _INCL_APB_REQ
`define  _INCL_APB_REQ

`include "definition.sv"

class  apb_req;

    rand  bit [`APB_ADDR_WIDTH-1:0] addr;
    bit master_error;
    rand  bit [1:0] other_error;
    rand bit [2:0] prot;    
    bit [`APB_DATA_WIDTH-1:0] rdata;
    rand bit [$clog2(`APB_SLAVE_DEVICES) :0] sel_id;
    rand bit [(`APB_DATA_WIDTH / 8) -1:0] strb;
    rand bit valid;    
    rand bit [`APB_DATA_WIDTH-1:0] wdata;
    rand bit write;

    constraint addr_range { addr[`APB_ADDR_WIDTH-1:12] == 20'h20380;}

    function  new();
        this.master_error = 0;
        this.rdata = 0;
    endfunction //new()


    function  tsb_apb_req  pack_req();
        tsb_apb_req tsb_req;
        tsb_req.addr = this.addr;
        tsb_req.master_error = this.master_error;        
        tsb_req.other_error = this.other_error;
        tsb_req.prot = this.prot;
        tsb_req.rdata = this.rdata;
        tsb_req.sel_id = this.sel_id;
        tsb_req.strb = this.strb;
        tsb_req.valid = this.valid;                
        tsb_req.wdata = this.wdata;
        tsb_req.write = this.write;

        return tsb_req;
    endfunction



endclass // apb_req



`endif

