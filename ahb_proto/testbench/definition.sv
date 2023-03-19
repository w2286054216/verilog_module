
/**********************************************************************************************************************************
* File Name:     definition.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:
*
*
* Version:         0.1
*********************************************************************************************************************************/



`ifndef  DEFINITION_SV
`define  DEFINITION_SV

`define  AHB_ADDR_WIDTH    32
`define  AHB_DATA_WIDTH    32

`define  AHB_SLAVE_DEVICES   2

`define  AHB_TRANS_TIMES      40


`define  SLAVES_BASE_ADDR      32'h20304000

`define  AHB_SPACE_WIDTH       16

`define  SLAVE1_ADDR_OFFSET    16'h400

`define  SLAVE2_ADDR_OFFSET    16'h800    

`define  SIMV

`endif

