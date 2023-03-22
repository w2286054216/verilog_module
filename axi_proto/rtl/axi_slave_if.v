
/*******************************************************************************
* Module Name:     axi_slave_if
* Author:          wuqlan
* Email:           
* Date Created:    2023/2/19
* Description:     AXI slave interface.
*                  Address and data bus widths are configurable using 
*                  AXI_ADDR_WIDTH and AXI_DATA_WIDTH parameters.
*
* Version:         0.1
*************************************************************************/


module axi_slave_if #(  parameter  AXI_ADDR_WIDTH = 32,
                        parameter  AXI_DATA_WIDTH = 32,
                        parameter  AXI_ID_WIDTH  = 16,
                        localparam  AXI_WSTRB_WIDTH  = AXI_DATA_WIDTH >> 3 )
                    (
    
    input  axi_clk_in,
    input  axi_rstn_in,

    /*--------write address channel------*/
    input   [AXI_ADDR_WIDTH -1:0]  axi_awaddr_in,
    input   [1:0]  axi_awburst_in,
    input   [3:0]  axi_awcache_in,
    input   [AXI_ID_WIDTH -1:0]  axi_awid_in,
    input   [7:0]  axi_awlen_in,
    input   [2:0]  axi_awprot_in,
    output  reg  axi_awready_out,
    input   [2:0]  axi_awsize_in,
    input   axi_awvalid_in,


    /*--------write data channel--------------*/
    input   [ AXI_ID_WIDTH -1:0]  axi_wid_in,
    input   [AXI_DATA_WIDTH -1:0]  axi_wdata_in,
    input   [AXI_WSTRB_WIDTH -1:0]  axi_wstrb_in,
    input   axi_wlast_in,
    input   axi_wvalid_in,
    output  reg  axi_wready_out,


    /*----------write resp channel-------*/
    output  reg  [AXI_ID_WIDTH -1:0]  axi_bid_out,
    output  reg  axi_bvalid_out,
    input   axi_bready_in,
    output  reg  axi_bresp_out,


    /*--------read adddress  channel*/
    input   [AXI_ADDR_WIDTH -1:0]  axi_araddr_in,
    input   [1:0]  axi_arburst_in,
    input   [3:0]  axi_arcache_in,
    input   [AXI_ID_WIDTH -1: 0]  axi_arid_in,
    input   [7:0]  axi_arlen_in,
    input   [2:0]  axi_arprot_in,
    input   [2:0]  axi_arsize_in,
    input   axi_arvalid_in,
    output  reg  axi_arready_out,


    /*-------read resp channel-----------*/
    output  reg  [AXI_ID_WIDTH -1:0]  axi_rid_out,
    output  reg  [AXI_DATA_WIDTH -1:0]  axi_rdata_out,
    output  reg  [1:0]  axi_rresp_out,
    output  reg  axi_rlast_out,
    output  reg  axi_rvalid_out,
    input   axi_rready_in,


    /*----------other module----------------*/
    output  reg  [AXI_ADDR_WIDTH -1:0]  other_addr_out,
    output  reg  [2:0]  other_cache_out,
    output  other_clk_out,
    input   other_error_in,
    output  reg  [2:0]  other_prot_out,
    input   [AXI_DATA_WIDTH -1:0]  other_rdata_in,
    input   other_ready_in,
    output  reg  other_sel_out,
    output  reg  other_size_out,
    output  reg  [AXI_WSTRB_WIDTH -1:0]  other_strb_out,
    output  reg  [AXI_DATA_WIDTH -1:0]  other_wdata_out,
    output  reg  other_write_out

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


/*axi write address channel state*/
localparam   AW_STATE_IDLE      =    0;
localparam   AW_STATE_TRANS     =    1;
localparam   AW_STATE_FINISH    =    2;
localparam   AW_STATE_UNRECV    =    3;
localparam   AW_STATE_ERROR     =    4;

/*axi read address channel state*/
localparam   AR_STATE_IDLE      =    0;
localparam   AR_STATE_TRANS     =    1;
localparam   AR_STATE_FINISH    =    2;
localparam   AR_STATE_UNRECV    =    3;
localparam   AR_STATE_ERROR     =    4;


// registers share
reg  [AXI_ADDR_WIDTH -1:0]  axi_addr;
reg  [1:0]  axi_burst;
reg  [3:0]  axi_cache;
reg  axi_error;
reg  [7:0]  axi_len;
reg  [2:0]  axi_prot;
reg  [2:0]  axi_size;
reg  axi_write;


/*--------write address channel registers--------*/
reg  [5:0]  aw_next_state;
reg  [5:0]  aw_state;
reg  [1:0]  untrans_wdata;


/*------------write data channel register--------*/
reg  [7:0]  wdata_len;
reg  [7:0]  wdata_counter;
reg  [1:0]  wdata_burst;





/*------------read data channel registers---*/
reg  [5:0]  ar_next_state;
reg  [5:0]  ar_state;
reg  [1:0]  untrans_rdata;

/*--------read data channel register------------*/
reg  [7:0]  rdata_len;
reg  [7:0]  rdata_counter;
reg  [1:0]  rdata_burst;





/*-----------write address channel----------------*/
// write address channel fsm
always @(posedge axi_clk_in or negedge axi_rstn_in) begin

    aw_next_state = 0;
    if (!axi_rstn_in) begin
        aw_next_state[AW_STATE_IDLE] = 1'd1;
    end 
    else begin
        case (1'd1)
            aw_state[AW_STATE_IDLE]: begin
                if ( axi_awvalid_in && !untrans_wdata[1])
                    aw_next_state[AW_STATE_TRANS]  =  1'd1;
                else
                    aw_next_state[AW_STATE_IDLE]  =  1'd1;
            end

            aw_state[AW_STATE_TRANS]: begin
                if (axi_awvalid_in)
                    aw_next_state[AW_STATE_FINISH]  =  1'd1;
                else
                    aw_next_state[AW_STATE_ERROR]  =  1'd1;
            end

            aw_state[AW_STATE_FINISH] ||  aw_state[AW_STATE_UNRECV] :begin
                if (untrans_wdata[1])
                    aw_next_state[AW_STATE_UNRECV]  =  1'd1;
                else
                    aw_next_state[AW_STATE_IDLE]    =  1'd1;
            end

            aw_state[AW_STATE_ERROR]: aw_next_state[AW_STATE_IDLE]  =  1'd1;

        endcase

    end

end

always @(posedge axi_clk_in) begin
    aw_state  <= aw_next_state;
end


always @(posedge axi_clk_in or negedge axi_rstn_in) begin

    if (!axi_rstn_in) begin
            axi_addr             <=    0;
            axi_burst            <=    0;
            axi_cache            <=    0;
            axi_len              <=    0;
            axi_prot             <=    0;
            axi_size             <=    0;
            axi_write            <=    0;

            axi_awready_out      <=    1;
    end
    else begin
        case(1'd1)
            aw_state[AW_STATE_IDLE]:  ;

            aw_state[AW_STATE_TRANS]: begin
                axi_awready_out      <=    1;
            end

            aw_state[AW_STATE_FINISH]: begin
                axi_addr             <=    axi_awaddr_in;
                axi_burst            <=    axi_awburst_in;
                axi_cache            <=    axi_awburst_in;
                axi_len              <=    axi_awlen_in;
                axi_prot             <=    axi_awprot_in;
                axi_size             <=    axi_awsize_in;
                axi_write            <=    1;
                
                axi_awready_out      <=    untrans_wdata[1] ? 0: 1;
                untrans_wdata        <=    ( untrans_wdata + 1 );
            end

            aw_state[AW_STATE_UNRECV]: axi_awready_out         <=    0;

            aw_state[AW_STATE_ERROR]: begin
                axi_error            <=    1;
                axi_awready_out      <=    1;
            end

            default: ;

        endcase

    end

end



// write data channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
        if ( !axi_rstn_in || !untrans_wdata) begin
            other_addr_out           <=   0;
            other_cache_out          <=   0;
            other_prot_out           <=   0;
            other_sel_out            <=   0;
            other_strb_out           <=   0;
            other_wdata_out          <=   0;
            other_write_out          <=   0;

            axi_wready_out           <=   1;
        end
        else if ( other_ready_in ) begin
            
            other_addr_out        <=   !wdata_counter ? axi_addr: get_next_addr(other_addr_out, other_size_out, 
                                        other_wdata_out, wdata_len);
            other_cache_out       <=   !wdata_counter ? axi_cache: other_cache_out;
            other_prot_out        <=   !wdata_counter ? axi_prot: other_prot_out;
            other_sel_out         <=   !wdata_counter ? 0: (axi_wvalid_in? 1: 0);
            other_strb_out        <=   axi_wstrb_in;
            other_wdata_out       <=   axi_wdata_in;
            other_write_out       <=   1;
            
            wdata_burst           <=   !wdata_counter ? axi_burst: wdata_burst;
            wdata_counter         <=   !wdata_counter ? axi_len : (axi_wvalid_in ? (wdata_counter - 1) : wdata_counter);

            axi_bid_out           <=   axi_wid_in;
            axi_awready_out       <=   !wdata_counter ? 0: (axi_wvalid_in? (axi_wready_out?0: 1): 0);
        end
        else
            axi_awready_out       <=   0;
end


// write resp channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
        if (!axi_rstn_in || !axi_wvalid_in ) begin
            axi_bid_out            <=  0;
            axi_bresp_out          <=  0;
            axi_bvalid_out         <=  0;
        end
        else begin
            axi_bresp_out          <=  other_error_in? 2'd2: 2'd0;
            axi_bvalid_out         <=  other_ready_in? 1: 0;
        end
end








/*-----------read address channel---------*/
// read address channel fsm
always @(posedge axi_clk_in or negedge axi_rstn_in) begin

    ar_next_state = 0;
    if (!axi_rstn_in) begin
        ar_next_state[AR_STATE_IDLE] = 1'd1;
    end 
    else begin
        case (1'd1)
            ar_state[AR_STATE_IDLE]: begin
                if ( axi_arvalid_in && !untrans_rdata[1])
                    ar_next_state[AR_STATE_TRANS]  =  1'd1;
                else
                    ar_next_state[AR_STATE_IDLE]  =  1'd1;
            end

            ar_state[AR_STATE_TRANS]: begin
                if (axi_arvalid_in)
                    ar_next_state[AR_STATE_FINISH]  =  1'd1;
                else
                    ar_next_state[AR_STATE_ERROR]  =  1'd1;
            end

            ar_state[AR_STATE_FINISH] ||  ar_state[AR_STATE_UNRECV] :begin
                if (untrans_rdata[1])
                    ar_next_state[AR_STATE_UNRECV]  =  1'd1;
                else
                    ar_next_state[AR_STATE_IDLE]    =  1'd1;
            end

            ar_state[AR_STATE_ERROR]: ar_next_state[AR_STATE_IDLE]  =  1'd1;

        endcase

    end

end

always @(posedge axi_clk_in) begin
    ar_state  <= ar_next_state;
end


always @(posedge axi_clk_in or negedge axi_rstn_in) begin

    if (!axi_rstn_in) begin
            axi_addr             <=    0;
            axi_burst            <=    0;
            axi_cache            <=    0;
            axi_len              <=    0;
            axi_prot             <=    0;
            axi_size             <=    0;
            axi_write            <=    0;

            axi_awready_out      <=    1;
    end
    else begin
        case(1'd1)
            aw_state[AW_STATE_IDLE]:  ;

            aw_state[AW_STATE_TRANS]: begin
                axi_arready_out      <=    1;
            end

            aw_state[AW_STATE_FINISH]: begin
                axi_addr             <=    axi_awaddr_in;
                axi_burst            <=    axi_awburst_in;
                axi_cache            <=    axi_awburst_in;
                axi_len              <=    axi_awlen_in;
                axi_prot             <=    axi_awprot_in;
                axi_size             <=    axi_awsize_in;
                axi_write            <=    1;
                
                axi_awready_out      <=    untrans_wdata[1] ? 0: 1;
                untrans_wdata        <=    ( untrans_wdata + 1 );
            end

            aw_state[AW_STATE_UNRECV]: axi_arready_out         <=    0;

            aw_state[AW_STATE_ERROR]: begin
                axi_error            <=    1;
                axi_awready_out      <=    1;
            end

            default: ;

        endcase

    end

end




// write data channel
always @(posedge axi_clk_in or negedge axi_rstn_in) begin
        if ( !axi_rstn_in || !untrans_rdata) begin
            axi_wready_out           <=   1;
        end
        else if ( other_ready_in ) begin
            
            other_addr_out        <=   !rdata_counter ? axi_addr: get_next_addr(other_addr_out, other_size_out, 
                                        rdata_burst, rdata_len);
            other_cache_out       <=   !rdata_counter ? axi_cache: other_cache_out;
            other_prot_out        <=   !rdata_counter ? axi_prot: other_prot_out;
            other_sel_out         <=   !rdata_counter ? 0: (axi_wvalid_in? 1: 0);
            other_write_out       <=   0;
            
            wdata_burst           <=   !rdata_counter ? axi_burst: wdata_burst;
            wdata_counter         <=   !rdata_counter ? axi_len : (axi_wvalid_in ? (wdata_counter - 1) : wdata_counter);

        end
end









function  [AXI_ADDR_WIDTH - 1:0] get_next_addr( input [AXI_ADDR_WIDTH - 1: 0] cur_addr, 
                                input  [2:0] size, input [1:0]  burst, input [7:0] len);

    case  (burst)
        AXI_BURST_RESERVED:   get_next_addr  =  0;
        AXI_BURST_FIXED: get_next_addr  =  cur_addr;
        AXI_BURST_INCR:  get_next_addr  =  cur_addr + (1 << size);
        AXI_BURST_WRAP:  get_next_addr  = (( cur_addr + ( 1<<size ) ) & (1 << (len + size + 1)) )  !=  
                                    (cur_addr & (1 << (len + size + 1)))?
                                cur_addr & (1 << (len + size + 1)): cur_addr + (1 << size);

    
    endcase
    
endfunction








endmodule //axi_slave_if



