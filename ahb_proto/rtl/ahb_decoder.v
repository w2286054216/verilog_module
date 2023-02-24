
/***********************************************************************************************************
* Module Name:     ahb_decoder
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB decoder.
*                  Address and sel bus widths are configurable using AHB_ADDR_WIDTH and SLAVE_DEVICES parameters.
*
* Version:         0.1
************************************************************************************************************/

module ahb_decoder (
    bus_addr_in,
    bus_clk_in,
    bus_rstn_in,
    slave_sel_out,
    multi_ready_in,
    multi_sel_out
    
);


parameter AHB_ADDR_WIDTH = 32;
parameter  SLAVE_DEVICES = 4;


/*slave devices address space*/
localparam  SLAVE_DEVICE1 = 32'h45680;
localparam  SLAVE_DEVICE2 = 32'h45681;
localparam  SLAVE_DEVICE3 = 32'h45682;
localparam  SLAVE_DEVICE4 = 32'h45683;


input [AHB_ADDR_WIDTH -1:0]  bus_addr_in;
input   bus_clk_in;
input   bus_rstn_in;
input   multi_ready_in;
output [SLAVE_DEVICES -1:0] slave_sel_out;
output [SLAVE_DEVICES -1:0] multi_sel_out;


reg [AHB_ADDR_WIDTH-1: 0] addr_cur;
reg [AHB_ADDR_WIDTH-1: 0] addr_next;
reg [SLAVE_DEVICES -1: 0]  slave_sel_out;
reg [ $clog2(SLAVE_DEVICES) + 1 : 0] multi_sel_out;

///////////////////////////Combinational logic//////////////////////////////////////////////////


/*get slave device sel*/
always @(addr_next) begin

    case (addr_next[AHB_ADDR_WIDTH-1:12])
    SLAVE_DEVICE1: slave_sel_out = 4'd1;
    SLAVE_DEVICE2: slave_sel_out = 4'd2;
    SLAVE_DEVICE3: slave_sel_out = 4'd4;
    SLAVE_DEVICE4: slave_sel_out = 4'd8;
        
    endcase
    
end

always @(addr_cur) begin
    case (addr_cur[AHB_ADDR_WIDTH-1:12])
    SLAVE_DEVICE1: multi_sel_out =  1;
    SLAVE_DEVICE2: multi_sel_out =  2;
    SLAVE_DEVICE3: multi_sel_out =  3;
    SLAVE_DEVICE4: multi_sel_out =  4;
        
    endcase
    
end



//////////////////////////////////////Sequential logic//////////////////////////////////////////////////


always @(posedge bus_clk_in or negedge bus_rstn_in) begin
        if (!bus_rstn_in) begin
            addr_cur <= 0;
            addr_next <= 0;
            
        end
        else
            if (multi_ready_in) begin
                addr_cur <= addr_next;
                addr_next <= bus_addr_in;
            end

    
end




endmodule //ahb_decoder


