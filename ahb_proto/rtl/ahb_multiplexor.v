

/***********************************************************************************************************
* Module Name:     ahb_multiplexor
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB multiplexor.
*                  Data and sel bus widths are configurable using AHB_DATA_WIDTH and SLAVE_DEVICES parameters.
*
* Version:         0.1
************************************************************************************************************/

module ahb_multiplexor (

    decoder_sel_in,
    bus_clk_in,
    bus_rstn_in,

    master_rdata_out,
    master_ready_out,
    master_resp_out,

    slave1_readyout_in,
    slave1_rdata_in,
    slave1_resp_in,
    slave2_readyout_in,
    slave2_rdata_in,
    slave2_resp_in,
    slave3_readyout_in,
    slave3_rdata_in,
    slave3_resp_in,
    slave4_readyout_in,
    slave4_rdata_in,
    slave4_resp_in
    
);


parameter AHB_DATA_WIDTH = 32;
parameter SLAVE_DEICES = 4;

localparam  SLAVE1_DEVICE = 1;
localparam  SLAVE2_DEVICE = 2;
localparam  SLAVE3_DEVICE = 3;
localparam  SLAVE4_DEVICE = 4;


input  bus_clk_in;
input  bus_rstn_in;
input [$clog2(SLAVE_DEICES) + 1: 0] decoder_sel_in;


input  slave1_readyout_in;
input [AHB_DATA_WIDTH-1: 0] slave1_rdata_in;
input  slave1_resp_in;
input  slave2_readyout_in;
input [AHB_DATA_WIDTH-1: 0] slave2_rdata_in;
input  slave2_resp_in;
input  slave3_readyout_in;
input [AHB_DATA_WIDTH-1: 0] slave3_rdata_in;
input  slave3_resp_in;
input  slave4_readyout_in;
input [AHB_DATA_WIDTH-1: 0] slave4_rdata_in;
input  slave4_resp_in;



output [AHB_DATA_WIDTH-1: 0] master_rdata_out;
output  master_ready_out;
output  master_resp_out;



reg [AHB_DATA_WIDTH -1:0] master_rdata;
reg master_resp;
reg master_ready;



always @(posedge bus_clk_in or negedge bus_rstn_in) begin
    if (!bus_rstn_in) begin
        master_rdata <= 0;
        master_ready <=1;
        master_resp <= 0;
        
    end
    else
        case (decoder_sel_in)
        SLAVE1_DEVICE:begin
            master_rdata <= slave1_rdata_in;
            master_ready <= slave1_readyout_in;
            master_resp <= slave1_resp_in;
        end

        SLAVE2_DEVICE:begin
            master_rdata <= slave2_rdata_in;
            master_ready <= slave2_readyout_in;
            master_resp <= slave2_resp_in;
        end

        SLAVE3_DEVICE:begin
            master_rdata <= slave3_rdata_in;
            master_ready <= slave3_readyout_in;
            master_resp <= slave3_resp_in;
        end

        SLAVE4_DEVICE:begin
            master_rdata <= slave4_rdata_in;
            master_ready <= slave4_readyout_in;
            master_resp <= slave4_resp_in;
        end

        default: begin
            master_rdata  <=  0;
            master_ready  <=  1;
            master_resp   <=  0;
        end

        endcase

end




endmodule //ahb_multiplexor

