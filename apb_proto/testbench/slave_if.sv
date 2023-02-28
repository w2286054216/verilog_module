
/**********************************************************************************
* File Name:     slave_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Connect testbench to  APB slave interface.
*
*
* Version:         0.1
********************************************************************************/


`ifndef  SLAVE_IF_SV
`define  SLAVE_IF_SV

`include "definition.sv"

interface slave_if;
    
    bit  [`APB_ADDR_WIDTH-1:0]  addr;
    bit  clk;
    bit  other_error;
    bit  [`APB_DATA_WIDTH-1:0]  rdata;
    bit  ready;    
    bit  sel;
    bit  slave_error;
    bit  [`APB_DATA_WIDTH-1:0]  wdata;
    bit  write;

    `ifdef  APB_PROT
        bit  [2:0]  prot;    
    `endif
    `ifdef  APB_WSTRB
        bit  [(`APB_DATA_WIDTH / 8) -1:0]  strb;
    `endif

    clocking cb @(negedge clk);
        input  addr, slave_error,  
                `ifdef  APB_PROT
                    prot, 
                `endif
                `ifdef  APB_WSTRB
                    strb, 
                `endif
                sel, wdata, write;
        output  other_error, rdata, ready;
    endclocking

    modport TSB_SLAVE_IF (clocking cb, input clk);


endinterface //master_if

typedef virtual slave_if.TSB_SLAVE_IF  VTSB_SLAVE_IF;


`endif

