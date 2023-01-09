
/**********************************************************************************************************************************
* File Name:     master_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Interface to connect testbench and APB master interface.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef  _INCL_MASTER_IF
`define  _INCL_MASTER_IF

`include "definition.sv"

interface master_if;
    
    bit [`APB_ADDR_WIDTH-1:0] addr;
    bit clk;
    bit master_error;   
    bit other_error;    
    bit [2:0] prot;    
    bit ready;
    bit [`APB_DATA_WIDTH-1:0] rdata;
    bit [$clog2(`APB_SLAVE_DEVICES) :0] sels;
    bit [(`APB_DATA_WIDTH / 8) -1:0] strb;
    bit [`APB_DATA_WIDTH-1:0] wdata;
    bit write;
    bit valid;

    clocking sb @(negedge clk);
        input  master_error, ready, rdata;
        output addr, other_error, prot, sels, strb, wdata, write, valid;
    endclocking

    modport TSB_MASTER (clocking sb, input clk);

endinterface //master_if


typedef virtual master_if.TSB_MASTER  VTSB_MASTER_T;


`endif

