
/*******************************************************************************
* Module Name:     axi_master_if
* Author:          wuqlan
* Email:           
* Date Created:    2023/2/19
* Description:     AXI master interface.
*                  Address and data axi widths are configurable using 
*                  AXI_ADDR_WIDTH and AXI_DATA_WIDTH parameters.
*
* Version:         0.1
*************************************************************************/
module axi_master_if #( parameter AXI_ADDR_WIDTH = 32, 
                        parameter  AXI_DATA_WIDTH = 32, 
                        parameter  AXI_ID_WIDTH  = 16,
                        localparam  AXI_WSTRB_WIDTH  = AXI_DATA_WIDTH >> 3) 
                    (

    input  axi_clk_in,
    input  axi_rstn_in,


    //----------write  address  channel-----------//
    output  [AXI_ADDR_WIDTH -1: 0]  axi_awaddr_out,
    output  [1:0]  axi_awburst_out,
    output  [3:0]  axi_awcache_out,
    output  reg  [AXI_ID_WIDTH -1:0]  axi_awid_out,
    output  [7:0]  axi_awlen_out,
    output  [2:0]  axi_awprot_out,
    output  [2:0]  axi_awsize_out,
    output  reg  axi_awvalid_out,
    input   axi_awready_in,



    //----------write  data  channel------------//
    output  reg  [AXI_DATA_WIDTH -1:0]  axi_wdata_out,
    output  reg  [AXI_ID_WIDTH -1:0]  axi_wid_out,
    output  reg  axi_wlast_out,
    input   reg  axi_wready_in,
    output  reg [AXI_WSTRB_WIDTH -1:0]  axi_wstrb_out,
    output  reg  axi_wvalid_out,

    //---------write resp channel-------------//
    input   [AXI_ID_WIDTH -1:0] axi_bid_in,
    output  reg  axi_bready_out,
    input   [1:0] axi_bresp_in,
    input   axi_bvalid_in,


    //---------read address channel------------//
    output  [AXI_ADDR_WIDTH -1: 0]  axi_araddr_out,
    output  [1:0]   axi_arburst_out,
    output  [3:0]   axi_arcache_out,
    input   axi_arready_in,    
    output  reg  [AXI_ID_WIDTH -1:0]  axi_arid_out,
    output  [7:0]  axi_arlen_out,
    output  [2:0]  axi_arprot_out,
    output  [2:0]  axi_arsize_out,
    output  reg  axi_arvalid_out,


    //--------read data channel-------------//
    input  [AXI_DATA_WIDTH -1:0]  axi_rdata_in,
    input  [AXI_ID_WIDTH -1:0]  axi_rid_in,
    input  axi_rlast_in,
    input  [1:0] axi_rresp_in,
    input  axi_rvalid_in,
    output  reg  axi_rready_out,


    //----------other module--------------//
    input   [AXI_ADDR_WIDTH-1:0]  other_addr_in,
    input   [1:0]  other_burst_in,
    input   [3:0]  other_cache_in,
    output  other_clk_out,
    output  reg  other_error_out,
    input   other_error_in,
    input   [7:0] other_len_in,
    input   other_order_in,
    input   [2:0] other_prot_in,
    output  other_rbusy_out,
    output  reg  [AXI_DATA_WIDTH-1:0]  other_rdata_out, 
    output  reg  other_ready_out,       
    input   other_sel_in,
    input   [2:0]  other_size_in,
    input   [AXI_WSTRB_WIDTH -1:0]  other_strb_in,
    input   other_valid_in,
    output  other_wbusy_out,
    input   other_write_in,   
    input   [AXI_DATA_WIDTH-1:0]  other_wdata_in

);



/*AXI burst type*/
localparam AXI_BURST_FIXED = 2'd0;
localparam AXI_BURST_INCR = 2'd1;
localparam AXI_BURST_WRAP = 2'd2;
localparam AXI_BURST_RESERVED = 2'd3;


/*AXI trans response type*/
localparam AXI_RESP_OKAY =  2'd0;
localparam AXI_RESP_EXOKAY =  2'd1;
localparam AXI_RESP_SLVERR =  2'd2;
localparam AXI_RESP_DECERR =  2'd3;


/*---------write address state------------*/
localparam   AW_STATE_IDLE      =    0;
localparam   AW_STATE_TRANS     =    1;
localparam   AW_STATE_WAIT      =    2;
localparam   AW_STATE_FINISH    =    3;
localparam   AW_STATE_UNRECV    =    4;
localparam   AW_STATE_ERROR     =    5;

/*---------read address state------------*/
localparam   AR_STATE_IDLE      =    0;
localparam   AR_STATE_TRANS     =    1;
localparam   AR_STATE_WAIT      =    2;
localparam   AR_STATE_FINISH    =    3;
localparam   AR_STATE_UNRECV    =    4;
localparam   AR_STATE_ERROR     =    5;


// registers shared
reg  [AXI_ADDR_WIDTH -1:0]  axi_addr;
reg  [1:0]  axi_burst;
reg  [3:0]  axi_cache;
reg  [7:0]  axi_len;
reg  [2:0]  axi_prot;
reg  [2:0]  axi_size;



/*--------write address channel fsm------*/
reg  [5:0]  aw_next_state;
reg  [5:0]  aw_state;



// write address channel registers
reg  [1:0]  untrans_wdata;
reg  aw_write;


// write data registers
reg [7:0] wdata_len;



/*--------read address channel fsm------*/
reg  [5:0]  ar_next_state;
reg  [5:0]  ar_state;



// read address channel registers
reg  [1:0]  untrans_rdata;
reg  ar_read;


// other module register
reg  [AXI_WSTRB_WIDTH -1:0 ]  other_strb;
reg  [AXI_DATA_WIDTH -1:0]  other_wdata;
reg  other_error;



wire  address_unaligned;
wire  burst_fixed;
wire  burst_incr;
wire  burst_wrap;
wire  wdata_recved;
wire  other_len_2;
wire  other_cross_4kb;
wire  [AXI_ADDR_WIDTH -1:0] other_end_addr;
wire  other_len_valid;
wire  other_read_valid;
wire  other_size_valid;
wire  other_write_valid;
wire  other_ctrl_valid;

wire  untrans_aw;
wire  untrans_ar;



/*------------write address channel--------------*/

// write address channel fsm
always @(posedge axi_clk_in or negedge axi_rstn_in) begin

    aw_next_state = 0;
    if (!axi_rstn_in) begin
        aw_next_state[AW_STATE_IDLE] = 1'd1;
        
    end 
    else begin
        case (1'd1)
            aw_state[AW_STATE_IDLE]: begin
                if (other_write_in)
                    aw_next_state[AW_STATE_TRANS]  =  1'd1;
                else if (other_valid_in && other_sel_in && other_write_in)
                    aw_next_state[AW_STATE_ERROR]  =  1'd1;
                else
                    aw_next_state[AW_STATE_IDLE]  =  1'd1;
            end

            aw_state[AW_STATE_TRANS] || aw_state[AW_STATE_WAIT]: begin
                if (axi_awready_in)
                    aw_next_state[AW_STATE_FINISH]  =  1'd1;
                else
                    aw_next_state[AW_STATE_WAIT]  =  1'd1;
            end

            aw_state[AW_STATE_FINISH] || aw_state[AW_STATE_UNRECV]:begin
                if (untrans_wdata[1])
                    aw_next_state[AW_STATE_UNRECV]  =  1'd1;
                else
                    aw_next_state[AW_STATE_IDLE]  =  1'd1;
            end

            aw_state[AW_STATE_ERROR]: aw_next_state[AW_STATE_IDLE]  =  1'd1;

        endcase

    end

end


always @(negedge axi_clk_in) begin
    aw_state  <= aw_next_state;
end


always @(posedge axi_clk_in or negedge axi_rstn_in) begin
    
    if (!axi_rstn_in) begin
        axi_addr          <=  0;
        axi_burst         <=  0;
        axi_cache         <=  0;
        axi_len           <=  0;
        axi_prot          <=  0;
        axi_size          <=  0;


        axi_awid_out      <=  0;
        other_strb        <=  0;
        other_wdata       <=  0;

    end
    else begin
        case(1'd1)
            aw_state[AW_STATE_IDLE]: ;

            aw_state[AW_STATE_TRANS]: begin
                axi_addr          <=  other_addr_in;
                axi_burst         <=  other_burst_in;
                axi_cache         <=  other_cache_in;
                axi_len           <=  other_len_in;
                axi_prot          <=  other_prot_in;
                axi_size          <=  other_size_in;

                axi_awvalid_out   <=  1;

                axi_awid_out      <=  other_order_in?axi_awid_out:(axi_awid_out + 1);
                aw_write          <=  1;

                untrans_wdata     <=  (untrans_wdata + 1);

            end
            
            
            aw_state[AW_STATE_WAIT]: ;

            aw_state[AW_STATE_FINISH]: begin
                axi_addr          <=  0;
                axi_burst         <=  0;
                axi_cache         <=  0;
                axi_len           <=  0;
                axi_prot          <=  0;
                axi_size          <=  0;

                axi_awvalid_out   <=  0;

                aw_write          <=  0;
                
            end
            
            aw_state[AW_STATE_UNRECV]:begin
                if (wdata_len)
                    other_wdata  <=  other_wdata_in;
                else
                    other_wdata  <= 0;

            end

            aw_state[AW_STATE_ERROR]: begin
                other_ready_out     <=   1;
                other_error_out     <=   1;
            end

        endcase

    end

end



//write data channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
    if (!axi_rstn_in || !untrans_wdata) begin
        axi_wid_out       <=  0;
        axi_wdata_out     <=  0;
        axi_wlast_out     <=  0;
        axi_wstrb_out     <=  0;
        axi_wvalid_out    <=  0;

    end
    else begin
        if (wdata_len && axi_wvalid_out && axi_wready_in) begin
            axi_wdata_out       <=  other_wdata;
            axi_wlast_out       <=  (wdata_len  == 1)?1:0;
            axi_wstrb_out       <=  other_error? 0:other_strb;
            axi_wvalid_out      <=  1;
        end 
        else if (!wdata_len && ( !axi_wvalid_out || axi_wready_in ) ) begin
            axi_wid_out       <=  untrans_wdata ? axi_awid_out: 0;
            axi_wdata_out     <=  untrans_wdata ? other_wdata: 0;
            axi_wlast_out     <=  untrans_wdata && (axi_len == 0) ? 1: 0;
            axi_wstrb_out     <=  other_strb;
            axi_wvalid_out    <=  1;

            wdata_len         <=  untrans_wdata ? axi_len: 0;
        end
    end
end



//write resp channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
    if (!axi_rstn_in) begin
        axi_bready_out       <=  1;
    end
    else begin
        other_error_out      <=  axi_bvalid_in && axi_bresp_in ? 1: 0;
    end
end



/*------------read address channel--------------*/

// read address channel fsm
always @(posedge axi_clk_in or negedge axi_rstn_in) begin

    ar_next_state = 0;
    if (!axi_rstn_in) begin
        aw_next_state[AW_STATE_IDLE] = 1'd1;
        
    end 
    else begin
        case (1'd1)
            ar_state[AW_STATE_IDLE]: begin
                if (other_write_in)
                    aw_next_state[AR_STATE_TRANS]  =  1'd1;
                else if (other_valid_in && other_sel_in && other_write_in)
                    aw_next_state[AR_STATE_ERROR]  =  1'd1;
                else
                    aw_next_state[AR_STATE_IDLE]  =  1'd1;
            end

            ar_state[AR_STATE_TRANS] || ar_state[AR_STATE_WAIT]: begin
                if (axi_awready_in)
                    aw_next_state[AW_STATE_FINISH]  =  1'd1;
                else
                    aw_next_state[AW_STATE_WAIT]  =  1'd1;
            end

            ar_state[AW_STATE_FINISH] || ar_state[AW_STATE_UNRECV]:begin
                if (untrans_wdata[1])
                    ar_next_state[AW_STATE_UNRECV]  =  1'd1;
                else
                    ar_next_state[AW_STATE_IDLE]  =  1'd1;
            end

            ar_state[AW_STATE_ERROR]: aw_next_state[AW_STATE_IDLE]  =  1'd1;

        endcase

    end

end


always @(negedge axi_clk_in) begin
    ar_state  <= ar_next_state;
end


//read address channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
    if (!axi_rstn_in) begin
        axi_arid_out           <=  0;
        axi_arvalid_out        <=  0;
    end
    else begin
        case(1'd1)
            ar_state[AR_STATE_IDLE]: ;

            ar_state[AR_STATE_TRANS]: begin
                axi_addr          <=  other_addr_in;
                axi_burst         <=  other_burst_in;
                axi_cache         <=  other_cache_in;
                axi_len           <=  other_len_in;
                axi_prot          <=  other_prot_in;
                axi_size          <=  other_size_in;

                axi_awvalid_out   <=  1;

                axi_arid_out      <=  other_order_in?axi_arid_out:(axi_arid_out + 1);
                ar_read           <=  1;

                untrans_rdata     <=  (untrans_rdata + 1);

            end
            
            
            aw_state[AR_STATE_WAIT]: ;

            aw_state[AR_STATE_FINISH]: begin
                axi_addr          <=  0;
                axi_burst         <=  0;
                axi_cache         <=  0;
                axi_len           <=  0;
                axi_prot          <=  0;
                axi_size          <=  0;

                axi_awvalid_out   <=  0;

                aw_write          <=  0;
                
            end
            
            ar_state[AR_STATE_UNRECV]:;

            ar_state[AW_STATE_ERROR]: begin
                other_ready_out     <=   1;
                other_error_out     <=   1;
            end

            default: ;
                
        endcase

    end

end


//read data channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
    if (!axi_rstn_in || !untrans_rdata) begin
        axi_rready_out          <=    1;
    end
    else begin
       if (axi_arvalid_out && axi_arready_in) begin
            other_error_out     <=  axi_rresp_in? 1: 0;        
            other_rdata_out     <=  axi_rdata_in;
            other_ready_out     <=  axi_rready_out & axi_rvalid_in;
       end
       else begin
            other_error_out     <=  0;        
            other_rdata_out     <=  0;
            other_ready_out     <=  0;
       end
    end
end




/*------write address channel--------*/
assign  axi_awaddr_out   =  aw_write ? axi_addr: 0;
assign  axi_awburst_out  =  aw_write ? axi_burst:  0;
assign  axi_awcache_out  =  aw_write ? axi_cache:  0;
assign  axi_awlen_out   =  aw_write ? axi_len:  0;
assign  axi_awprot_out  =  aw_write ? axi_prot:  0;
assign  axi_awsize_out  =  aw_write  ?  axi_size:  0;



/*-------------read address channel----------------*/
assign  axi_araddr_out   =  ar_read ? axi_addr: 0;
assign  axi_arburst_out  =  ar_read ? axi_burst:  0;
assign  axi_arcache_out  =  ar_read ? axi_cache:  0;
assign  axi_arlen_out   =  ar_read ? axi_len:  0;
assign  axi_arprot_out  =  ar_read ? axi_prot:  0;
assign  axi_arsize_out  =  ar_read  ?  axi_size:  0;



assign  address_unaligned  =  other_addr_in[7:0] & ((1 << other_size_in) - 1) ? 1: 0;


assign  other_ctrl_valid  =  other_sel_in && other_valid_in;
assign  burst_fixed  =  (other_burst_in == AXI_BURST_FIXED);
assign  burst_incr   =  (other_burst_in == AXI_BURST_INCR);
assign  burst_wrap   =  (other_burst_in == AXI_BURST_WRAP);
assign  other_end_addr  =  other_addr_in + (1 << (other_size_in + other_len_in + 1));
assign  other_cross_4kb  =  other_end_addr[15:12] != other_addr_in[15:12];
assign  other_len_2   =  !(other_len_in & ( other_len_in - 1));
assign  other_len_valid    =  !((other_cross_4kb && burst_incr) || (burst_wrap && !other_len_2));
assign  other_read_valid   =  other_size_valid && !other_write_in && other_len_valid;
assign  other_size_valid   =  (8<<other_size_in) < AXI_DATA_WIDTH ? 1:0;
assign  other_write_valid  =  other_size_valid && other_write_in && other_len_valid;

assign  untrans_aw  =  axi_awvalid_out  &&  !axi_awready_in;
assign  untrans_ar  =  axi_arvalid_out  &&  !axi_arready_in;

assign  wdata_recved  =  axi_wvalid_out && axi_wready_in;


endmodule //axi_master_if


