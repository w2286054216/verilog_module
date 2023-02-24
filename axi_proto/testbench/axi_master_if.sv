
/**********************************************************************************************************************************
* File Name:     master_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     Interface to connect testbench and APB master interface.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef  AXI_MASTER_IF
`define  AXI_MASTER_IF

`include "definition.sv"

interface axi_master_if;
    
    bit [`AHB_ADDR_WIDTH-1:0] addr;
    bit [2:0] burst;
    bit clk;
    bit delay;
    bit end_trans;
    bit master_error;   
    bit other_error;    
    bit [3:0] prot;
    bit [`AHB_DATA_WIDTH-1:0] rdata;    
    bit ready;
    bit [3:0] size;   
    bit [(`AHB_DATA_WIDTH / 8) -1:0] strb;
    bit [`AHB_DATA_WIDTH-1:0] wdata;
    bit write;
    bit valid;

    clocking cb @(negedge clk);
        input  master_error, ready, rdata;
        output addr, burst, delay, end_trans, other_error, prot, size, strb, wdata, write, valid;
    endclocking

    modport TSB_MASTER (clocking cb, input clk);

endinterface //master_if


typedef virtual axi_master_if.TSB_MASTER  VTSB_MASTER_T;


`endif

