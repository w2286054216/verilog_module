
/***************************************************************************************
* File Name:     apb_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB bus interface. Connect the slave devices to the master device.
*
*
* Version:         0.1
****************************************************************************************/


`ifndef  AHB_IF_SV
`define  AHB_IF_SV


`include "definition.sv"

interface ahb_if(input logic clk, rstn);
    
    wire  logic  [`AHB_ADDR_WIDTH-1:0]  addr;
    wire  logic  [2:0]  burst;
    wire  logic  [2:0]  size;
    wire  logic  [`AHB_DATA_WIDTH-1:0]  rdata;    
    wire  logic  ready;
    wire  logic  resp;

    `ifdef  AHB_PROT
        wire  logic  [3:0]  prot;
    `endif
    `ifdef  AHB_WSTRB
        wire  logic  [(`AHB_DATA_WIDTH / 8) -1:0]  strb;
    `endif

    wire  logic  [1:0]  trans;
    wire  logic  [`AHB_DATA_WIDTH-1:0]  wdata;
    wire  logic  write;

endinterface //ahb_if



interface  decoder_if(input logic clk, rstn);
    wire  logic  [`AHB_ADDR_WIDTH-1:0] addr;
    wire  logic  [`AHB_SLAVE_DEVICES:0] selx;
    wire  logic  master_ready;
    wire  logic  [$clog2(`AHB_SLAVE_DEVICES): 0]  multip_sel;
    
endinterface // decoder_if


interface  multip_if(input logic clk, rstn);

    wire  logic  [$clog2(`AHB_SLAVE_DEVICES): 0]  decoder_sel;

    wire  logic  [`AHB_DATA_WIDTH -1:0]  master_rdata;
    wire  logic  master_ready;
    wire  logic  master_resp;

    wire  logic  [ `AHB_SLAVE_DEVICES -1 : 0 ]  slaves_ready;
    wire  logic  [ `AHB_SLAVE_DEVICES -1 : 0 ]  slaves_resp;
    wire  logic  [`AHB_DATA_WIDTH -1:0]  slaves_rdata[`AHB_SLAVE_DEVICES -1: 0];

endinterface // multip_if


`endif

