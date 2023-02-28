
/**********************************************************************************
* File Name:     master_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Interface to connect testbench and APB master interface.
*
*
* Version:         0.1
********************************************************************************/


`ifndef  MASTER_IF_SV
`define  MASTER_IF_SV

`include "definition.sv"

interface master_if;
    
    bit  [`APB_ADDR_WIDTH-1:0]  addr;
    bit  clk;
    bit  master_error;
    bit  other_error;
    bit  ready;
    bit  [`APB_DATA_WIDTH-1:0]  rdata;
    bit  sel;
    bit  [`APB_DATA_WIDTH-1:0]  wdata;
    bit  write;

    `ifdef  APB_PROT
        bit  [2:0] prot;
    `endif
    `ifdef  APB_WSTRB
        bit  [(`APB_DATA_WIDTH / 8) -1:0] strb;
    `endif

    clocking cb @(negedge clk);
        input  master_error, ready, rdata;
        output addr, other_error,
                `ifdef APB_PROT
                    prot,
                `endif

                `ifdef  APB_WSTRB
                    strb, 
                `endif
                
                sel, wdata, write;
    endclocking

    modport TSB_MASTER_IF (clocking cb, input clk);

endinterface //master_if


typedef virtual master_if.TSB_MASTER_IF  VTSB_MASTER_IF;


`endif

