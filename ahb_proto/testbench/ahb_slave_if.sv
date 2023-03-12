
/*******************************************************************************
* File Name:     ahb_slave_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Connect testbench to  AHB slave interface.
*
*
* Version:         0.1
***********************************************************************************/


`ifndef  AHB_SLAVE_IF_SV
`define  AHB_SLAVE_IF_SV

`include "definition.sv"

interface ahb_slave_if;
    
    bit  [`AHB_ADDR_WIDTH-1:0] addr;
    bit  clk;
    bit  other_error;
    bit  ready;
    bit  [`AHB_DATA_WIDTH-1:0]  rdata;
    bit  sel;
    bit  slave_error;

    `ifdef  AHB_PROT
        bit  [3:0]  prot;
    `endif
    `ifdef  AHB_WSTRB
        bit  [(`AHB_DATA_WIDTH / 8) -1:0]  strb;
    `endif
    
    bit  [`AHB_DATA_WIDTH-1:0]  wdata;
    bit  write;


endinterface //ahb_slave_if

`endif

