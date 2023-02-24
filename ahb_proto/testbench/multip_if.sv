
/***************************************************************************************
* File Name:     multip_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB bus interface. Connect the slave devices to the master device.
*
*
* Version:         0.1
****************************************************************************************/


`ifndef  MULTIP_IF_SV
`define  MULTIP_IF_SV


`include "definition.sv"


interface  multip_if(input logic clk, rstn);

    wire logic [$clog2(`AHB_SLAVE_DEVICES): 0] decoder_sel;

    wire logic [`AHB_DATA_WIDTH -1:0] master_rdata;
    wire logic master_ready;
    wire logic master_resp;

    wire logic [ `AHB_SLAVE_DEVICES -1 : 0 ] slaves_ready;
    wire logic [ `AHB_SLAVE_DEVICES -1 : 0 ] slaves_resp;
    wire logic [`AHB_DATA_WIDTH -1:0] slaves_rdata[`AHB_SLAVE_DEVICES -1: 0];

endinterface // multip_if



`endif