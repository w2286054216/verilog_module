
/*****************************************************************************************
* File Name:     ahb_master_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Interface to connect testbench and AHB master interface.
*
*
* Version:         0.1
****************************************************************************************/


`ifndef  AHB_MASTER_IF
`define  AHB_MASTER_IF

`include "definition.sv"

interface ahb_master_if;
    
    bit  [`AHB_ADDR_WIDTH-1:0]  addr;
    bit  [2:0] burst;
    bit  busy;
    bit  clk;
    bit  delay;
    bit  master_error;
    bit  other_error;
    bit  [`AHB_DATA_WIDTH-1:0]  rdata; 
    bit  ready;
    bit  sel;
    bit  [2:0]  size;

    `ifdef  AHB_PROT
        bit  [3:0]  prot;
    `endif
    `ifdef  AHB_WSTRB
        bit  [(`AHB_DATA_WIDTH / 8) -1: 0]  strb;
    `endif

    bit  valid;
    bit  [`AHB_DATA_WIDTH-1:0]  wdata;
    bit  write;


endinterface //ahb_master_if

typedef  virtual  ahb_master_if  VTSB_MASTER_IF;

`endif
