
/**********************************************************************************************************************************
* File Name:     apb_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB bus interface. Connect the slave devices to the master device.
*
*
* Version:         0.1
*********************************************************************************************************************************/



`ifndef _INCL_APB_IF
`define _INCL_APB_IF


`include "definition.sv"

interface apb_if(input logic clk, rstn);
    
    wire  logic [`APB_ADDR_WIDTH-1:0] addr;
    wire  logic master_error_out;
    wire  logic master_error_in;
    wire  logic penable;
    wire  logic [2:0] prot;    
    wire  logic master_ready;
    wire  logic [`APB_DATA_WIDTH-1:0] rdata;
    wire  logic [`APB_SLAVE_DEVICES -1:0] sels;
    wire  logic [`APB_SLAVE_DEVICES -1:0] slave_error_out;
    wire  logic [`APB_SLAVE_DEVICES -1:0] slave_ready;
    wire  logic [(`APB_DATA_WIDTH / 8) -1:0] strb;
    wire  logic [`APB_DATA_WIDTH-1:0] wdata;
    wire  logic write;

    assign master_ready = slave_ready[ $clog2(sels) ];
    assign master_error_in = slave_error_out[ $clog2(sels)] ;


endinterface //master_if


`endif
