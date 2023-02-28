
/*********************************************************************************
* File Name:     definition.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:
*
*
* Version:         0.1
*******************************************************************************/



`ifndef  _INCL_DEFINITION
`define  _INCL_DEFINITION


`define  APB_DATA_WIDTH    32
`define  APB_ADDR_WIDTH    32


`define TEST_APB_REQ      30

`timescale  1ns/1ns


typedef struct {
    bit [`APB_ADDR_WIDTH -1: 0] addr;
    bit [`APB_DATA_WIDTH -1: 0] wdata;
    bit [`APB_DATA_WIDTH -1: 0] rdata;
    bit [2:0]  prot;
    bit [(`APB_DATA_WIDTH >> 3) -1:0] strb;
    bit write;
    bit valid;
    bit master_error;
    int unsigned sel_id;
    int unsigned  other_error;
    
} tsb_apb_req;


typedef struct {
    bit [`APB_ADDR_WIDTH -1: 0] addr;
    bit [`APB_DATA_WIDTH -1: 0] wdata;
    bit [`APB_DATA_WIDTH -1: 0] rdata;
    bit [2:0]  prot;
    bit [(`APB_DATA_WIDTH >> 3) -1:0] strb;
    bit write;
    bit slave_error;
    int unsigned  monitor_id;
    int unsigned  other_error;
    int unsigned  other_ready;
} tsb_apb_resp;





`endif

