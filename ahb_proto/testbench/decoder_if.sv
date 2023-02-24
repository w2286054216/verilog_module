/***************************************************************************************
* File Name:       decoder_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB bus interface. Connect the slave devices to the master device.
*
*
* Version:         0.1
****************************************************************************************/


`ifndef  DECODER_IF_SV
`define  DECODER_IF_SV


`include "definition.sv"

interface  decoder_if(input logic clk, rstn);
    wire  logic [`AHB_ADDR_WIDTH-1:0] addr;
    wire  logic [`AHB_SLAVE_DEVICES:0] selx;
    wire  logic master_ready;
    wire  logic [$clog2(`AHB_SLAVE_DEVICES): 0] multip_sel;
    
endinterface // decoder_if


`endif


