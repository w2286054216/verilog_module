
/*******************************************************************************
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB bus interface. Connect the slave devices to the master device.
*
*
* Version:         0.1
********************************************************************************/


`ifndef _INCL_APB_IF
`define _INCL_APB_IF


`include "definition.sv"

interface apb_if(input logic clk, rstn);
    
    wire  logic  [`APB_ADDR_WIDTH-1:0] addr;
    wire  logic  penable;
    wire  logic  [`APB_DATA_WIDTH-1:0] rdata;    
    wire  logic  ready;
    wire  logic  sel;
    wire  logic  [`APB_DATA_WIDTH-1:0]  wdata;
    wire  logic  write;

    `ifdef  APB_SLVERR
        wire  logic  master_error_out;      
        wire  logic  slave_error_in;
    `endif
    `ifdef  APB_PROT
        wire  logic  [2:0] prot;
    `endif
    `ifdef  APB_WSTRB
        wire  logic  [(`APB_DATA_WIDTH / 8) -1:0]  strb;    
    `endif


endinterface //master_if


`endif
