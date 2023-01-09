
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


`ifndef  _INCL_SLAVE_IF
`define  _INCL_SLAVE_IF

`include "definition.sv"

interface slave_if;
    
    bit [`APB_ADDR_WIDTH-1:0] addr;
    bit clk;
    bit other_error;    
    bit [2:0] prot;    
    bit ready;
    bit slave_ready;
    bit [`APB_DATA_WIDTH-1:0] rdata;
    bit sel;
    bit slave_error;    
    bit [(`APB_DATA_WIDTH / 8) -1:0] strb;
    bit [`APB_DATA_WIDTH-1:0] wdata;
    bit write;



    clocking sb @(negedge clk);
        input  addr, slave_error, slave_ready, prot, sel, strb, wdata, write;
        output  other_error, ready, rdata;
    endclocking

    modport TSB_SLAVE (clocking sb, input clk);


endinterface //master_if

typedef virtual slave_if.TSB_SLAVE  VTSB_SLAVE_T;


`endif

