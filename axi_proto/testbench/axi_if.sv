
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


`ifndef  AXI_IF_SV
`define  AXI_IF_SV


`include "definition.sv"

interface axi_if(input logic clk, rstn);
    
    wire  logic [`AHB_ADDR_WIDTH-1:0] addr;
    wire  logic [2:0] burst;
    wire  logic [2:0] size;
    wire  logic [3:0] prot;
    wire  logic [`AHB_DATA_WIDTH-1:0] rdata;
    wire  logic [(`AHB_DATA_WIDTH / 8) -1:0] strb;
    wire  logic [`AHB_DATA_WIDTH-1:0] wdata;
    wire  logic write;

endinterface //ahb_if


`endif
