
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


    clocking  cb  @(posedge clk);
        input   master_error, ready, rdata;
        output  addr, other_error,  sel, wdata, 
        
                `ifdef  APB_PROT
                    prot;
                `endif
                `ifdef  APB_WSTRB
                    strb;
                `endif
        
                write;

    endclocking




endinterface //master_if

typedef virtual master_if  VTSB_MASTER_IF;


`endif

