

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

module ahb_multiplexor #(
        parameter AHB_DATA_WIDTH = 32,
        parameter SLAVE_DEICES = 2
    )
(


    input   ahb_clk_in,
    output  reg  [AHB_DATA_WIDTH-1: 0] ahb_rdata_out,
    output  reg  ahb_ready_out,
    output  reg  ahb_resp_out,    
    input   ahb_rstn_in,
    input   [ $clog2(SLAVE_DEICES): 0] decoder_sel_in,


    /*------slave device output-----*/
    input  [AHB_DATA_WIDTH-1: 0]  slave1_rdata_in,    
    input  slave1_readyout_in,
    input  slave1_resp_in,
    input  [AHB_DATA_WIDTH-1: 0]  slave2_rdata_in,    
    input  slave2_readyout_in,
    input  slave2_resp_in
    
);

localparam  SLAVE_DEFAULT =  1;
localparam  SLAVE1_DEVICE =  2;
localparam  SLAVE2_DEVICE =  3;




always @(posedge ahb_clk_in) begin
    if (!ahb_rstn_in) begin
        ahb_rdata_out       <=  0;
        ahb_ready_out       <=  1;
        ahb_resp_out        <=  0;
        
    end
    else  begin
        case (decoder_sel_in)
            SLAVE_DEFAULT:begin
                ahb_ready_out   <=  0;
                ahb_resp_out    <=  1;
            end
            SLAVE1_DEVICE:begin
                ahb_rdata_out        <=  slave1_rdata_in;
                ahb_ready_out        <=  slave1_readyout_in;
                ahb_resp_out         <=  slave1_resp_in;
            end

            SLAVE2_DEVICE:begin
                ahb_rdata_out        <=  slave1_rdata_in;
                ahb_ready_out        <=  slave1_readyout_in;
                ahb_resp_out         <=  slave1_resp_in;
            end

            default: begin
                ahb_rdata_out        <=  0;
                ahb_ready_out        <=  1;
                ahb_resp_out         <=  0;
            end

        endcase
    end

end




endmodule //ahb_multiplexor

