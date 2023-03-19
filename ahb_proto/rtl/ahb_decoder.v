
/*********************************************************************************
* Module Name:     ahb_decoder
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB decoder.
*                  Address and sel bus widths are configurable using AHB_ADDR_WIDTH
*                  and SLAVE_DEVICES parameters.
*
* Version:         0.1
*********************************************************************************/

module ahb_decoder #(
        parameter  AHB_BASE_ADDR    =  32'h20304000,
        parameter  AHB_SPACE_WIDTH  =  16,
        parameter  AHB_ADDR_WIDTH   =  32,
        parameter  SLAVE_DEVICES    =  2
        )
(

    input   ahb_clk_in,
    input   ahb_rstn_in,

    input   [AHB_ADDR_WIDTH -1:0]  ahb_addr_in,
    input   multi_ready_in,
    output  reg  [$clog2(SLAVE_DEVICES) :0]  multi_sel_out,
    output  [SLAVE_DEVICES -1: 0]  slave_sel_out
    
);



/*slave devices address space*/
localparam  SLAVE_DEVICE1 = 16'h0;
localparam  SLAVE_DEVICE2 = 16'h400;
localparam  SLAVE_DEVICE3 = 16'h800;
localparam  SLAVE_DEVICE4 = 16'hc00;



reg  [AHB_ADDR_WIDTH-1: 0]  addr_cur;
reg  [AHB_ADDR_WIDTH-1: 0]  addr_next;
reg  [SLAVE_DEVICES -1: 0]  cur_slave_selx;
reg  [SLAVE_DEVICES -1: 0]  next_slave_selx;

wire  addr_valid;


///////////////////////////Combinational logic//////////////////////////////////////////////////


/*get slave device sel*/
always @(*) begin
    next_slave_selx  =  0;
    case (addr_next[AHB_SPACE_WIDTH -1: 0])
        SLAVE_DEVICE1: next_slave_selx  =  4'd1;
            SLAVE_DEVICE2: next_slave_selx  =  4'd2;
            SLAVE_DEVICE3: next_slave_selx  =  4'd4;
            SLAVE_DEVICE4: next_slave_selx  =  4'd8;
        default: next_slave_selx        =  0;
        
    endcase
    
end

always @(*) begin
    multi_sel_out  =  0;
    case (addr_cur[AHB_ADDR_WIDTH-1:10])
            SLAVE_DEVICE1: begin
                multi_sel_out           =   2;
                cur_slave_selx          =   1;
            end
            SLAVE_DEVICE2: begin
                multi_sel_out           =   3;
                cur_slave_selx          =   2;
            end
            SLAVE_DEVICE3: begin
                multi_sel_out           =   4;
                cur_slave_selx          =   4;
            end
            SLAVE_DEVICE4: begin
                multi_sel_out           =   5;
                cur_slave_selx          =   8;
            end
        default: begin
                multi_sel_out           =   1;
                cur_slave_selx          =   0;
            end
        
    endcase
    
end



////////////////////////Sequential logic/////////////////////////////

always @(posedge ahb_clk_in or negedge ahb_rstn_in) begin
        if (!ahb_rstn_in) begin
            addr_cur   <=  0;
            addr_next  <=  0;
        end
        else begin
            if (multi_ready_in) begin
                addr_cur   <=  addr_next;
                addr_next  <=  addr_valid? ahb_addr_in: 0;
            end
            else begin
                addr_cur   <=  addr_cur;
                addr_next  <=  addr_next;
            end
        end
end


assign  addr_valid  = (ahb_addr_in[AHB_ADDR_WIDTH -1: 16] ==  AHB_BASE_ADDR[AHB_ADDR_WIDTH -1: 16]);
assign  slave_sel_out  =  next_slave_selx | cur_slave_selx;


endmodule //ahb_decoder

