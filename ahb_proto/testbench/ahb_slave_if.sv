
/**********************************************************************************************************************************
* File Name:     slave_if.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Connect testbench to  APB slave interface.
*
*
* Version:         0.1
*********************************************************************************************************************************/


`ifndef  SLAVE_IF_SV
`define  SLAVE_IF_SV

`include "definition.sv"

interface ahb_slave_if;
    
    bit [`AHB_ADDR_WIDTH-1:0] addr;
    bit clk;
    bit other_error;    
    bit [3:0] prot;    
    bit ready;
    bit slave_ready;
    bit [`AHB_DATA_WIDTH-1:0] rdata;
    bit sel;
    bit slave_error;    
    bit [(`AHB_DATA_WIDTH / 8) -1:0] strb;
    bit [`AHB_DATA_WIDTH-1:0] wdata;
    bit write;



    clocking cb @(negedge clk);
        input  addr, slave_error, slave_ready, prot, sel, strb, wdata, write;
        output  other_error, ready, rdata;
    endclocking

    modport TSB_SLAVE (clocking cb, input clk);


endinterface //master_if

typedef virtual slave_if.TSB_SLAVE  VTSB_SLAVE_T;


`endif
