
/***********************************************************************************************************
* Module Name:     ahb_master_if
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB master interface.
*                  Address and data bus widths are configurable using AHB_ADDR_WIDTH and AHB_DATA_WIDTH parameters.
*
* Version:         0.1
************************************************************************************************************/

module ahb_master_if #(
                parameter  AHB_ADDR_WIDTH  =  32,
                parameter  AHB_DATA_WIDTH  =  32
                )
(


    input  ahb_clk_in,
    input  ahb_rstn_in,

    /*-----------ahb bus signal-----------*/
    output  reg  [AHB_ADDR_WIDTH-1: 0]  ahb_addr_out,
    output  reg  ahb_burst_out,
    output  reg  [ 3:0 ] ahb_prot_out,
    input   [AHB_DATA_WIDTH-1: 0]  ahb_rdata_in,
    input   ahb_ready_in,
    input   ahb_resp_in,
    output  reg  ahb_size_out,
    output  reg  [(AHB_DATA_WIDTH /8) -1:0]  ahb_strb_out,
    output  reg  ahb_trans_out,
    output  reg  [AHB_DATA_WIDTH-1: 0] ahb_wdata_out,
    output  reg  ahb_write_out,

    /*-----------other module signal----------------*/
    input   [AHB_ADDR_WIDTH -1: 0]  other_addr_in,
    input   other_burst_in,
    output  other_busy_out,
    output  other_clk_out,
    input   other_delay_in,
    input   other_error_in,    
    output  reg  other_error_out,
    input   other_end_in,
    input   [3:0]  other_prot_in,
    output  reg  [AHB_DATA_WIDTH-1: 0]  other_rdata_out,
    output  reg  other_ready_out,
    input   other_size_in,
    input   [(AHB_DATA_WIDTH /8) -1:0]  other_strb_in,
    input   other_valid_in,    
    input   [AHB_DATA_WIDTH-1: 0]  other_wdata_in,
    input   other_write_in

);







/*master burst type*/
localparam  AHB_BURST_SINGLE   =  3'd0;
localparam  AHB_BURST_INCR     =  3'd1;
localparam  AHB_BURST_WRAP4    =  3'd2;
localparam  AHB_BURST_INCR4    =  3'd3;
localparam  AHB_BURST_WRAP8    =  3'd4;
localparam  AHB_BURST_INCR8    =  3'd5;
localparam  AHB_BURST_WRAP16   =  3'd6;
localparam  AHB_BURST_INCR16   =  3'd7;


/*master trans type*/
localparam  AHB_TRANS_IDLE    = 2'd0;
localparam  AHB_TRANS_BUSY    = 2'd1;
localparam  AHB_TRANS_NONSEQ  = 2'd2;
localparam  AHB_TRANS_SEQ     = 2'd3;



/*ahb master state*/
localparam  STATE_RST               =  3'd0;
localparam  STATE_TRANS_IDLE        =  3'd1;
localparam  STATE_TRANS_BUSY        =  3'd2;
localparam  STATE_TRANS_NONSEQ      =  3'd3;
localparam  STATE_TRANS_SEQ         =  3'd4;
localparam  STATE_ERROR             =  3'd5;



reg  [2:0]  ahb_state;
reg  [3:0]  burst_counter;
reg  busy_2_seq;
reg  [2:0]  next_state;
reg  [1:0]  trans_unready;
reg  last_write;



reg [AHB_ADDR_WIDTH -1:0] ahb_addr_out;
reg [2:0] ahb_burst_out;
reg [2:0] ahb_size_out;
reg [(AHB_DATA_WIDTH /8)-1:0] ahb_strb_out;
reg [1:0] ahb_trans_out;
reg [AHB_DATA_WIDTH -1:0]  ahb_wdata_out;
reg ahb_write_out;
reg [AHB_ADDR_WIDTH - 1: 0] burst_addr;
reg [2:0] other_burst;
reg other_error_out;
reg [AHB_DATA_WIDTH -1:0]  other_rdata_out;
reg other_ready_out;



wire  burst_control_changed;
wire  cur_burst_incr;
wire  next_burst_incr;
wire  size_valid;


///////////////////////////Combinational logic//////////////////////////////////////////////////

/*get next burst addr*/
always @(*) begin
    if (!ahb_burst_out || !burst_counter)
        burst_addr = 0;
    else if(ahb_burst_out[0])
        burst_addr = ahb_addr_out + ( 2 << ahb_size_out);
    else begin
        case(ahb_burst_out)
        AHB_BURST_WRAP4: burst_addr = ( ahb_addr_out + (2 << ahb_size_out)) & (( 2 << ( ahb_size_out + 2) ) - 1)?
                             ahb_addr_out + ( 2 << ahb_size_out): 
                             ahb_addr_out - (6 << ahb_size_out);
        AHB_BURST_WRAP8: burst_addr = ( ahb_addr_out + (2 << ahb_size_out)) & (( 2 << (ahb_size_out + 3) ) - 1)?
                             ahb_addr_out + ( 2 << ahb_size_out): 
                             ahb_addr_out -  (14 << ahb_size_out);
        AHB_BURST_WRAP16: burst_addr = ( ahb_addr_out + (2 << ahb_size_out)) & (( 2 << ( ahb_size_out + 4) ) - 1)?
                             ahb_addr_out + ( 2 << ahb_size_out): 
                             ahb_addr_out - ( 30 << ahb_size_out);
        default: burst_addr = 0;
            
        endcase
    end
    
end


/*FSM*/
always @(*) begin

    if (!ahb_rstn_in)
        next_state = STATE_RST;
    else begin
        case (ahb_state)
            STATE_RST: begin
                if (other_valid_in && (other_error_in || !size_valid ))
                    next_state = STATE_ERROR;
                else if (!other_valid_in)
                    next_state = STATE_RST;
                else
                    next_state = STATE_TRANS_NONSEQ;

            end

            STATE_TRANS_IDLE: begin
                if ( !other_valid_in || (other_valid_in && other_error_in) || multi_resp_in || other_delay_in )
                    next_state = STATE_ERROR;
                else if ( other_end_in && !trans_unready ) 
                    next_state = STATE_RST;
                else if ( other_end_in )
                    next_state  = STATE_TRANS_IDLE;
                else
                    next_state = STATE_TRANS_NONSEQ;

            end

            STATE_TRANS_BUSY: begin
                if ( !other_valid_in || (other_valid_in && other_error_in) || multi_resp_in || 
                        (burst_control_changed && !cur_burst_incr ) )
                    next_state = STATE_ERROR;
                else if (!burst_counter)
                    next_state  = STATE_TRANS_NONSEQ;
                else if (other_delay_in)
                    next_state = STATE_TRANS_BUSY;
                else
                    next_state = STATE_TRANS_SEQ;
            end

            STATE_TRANS_NONSEQ: begin
                if ( !other_valid_in || (other_valid_in && other_error_in) || multi_resp_in || (!ahb_burst_out && other_delay_in ) 
                         )
                    next_state  = STATE_ERROR;
                else if (other_end_in )
                    next_state  = STATE_TRANS_IDLE;
                else if (other_delay_in)
                    next_state  = STATE_TRANS_BUSY;
                else if (ahb_burst_out)
                    next_state  = STATE_TRANS_SEQ;
                else 
                    next_state  = STATE_TRANS_NONSEQ;

            end

            STATE_TRANS_SEQ: begin
                if ( !other_valid_in || (other_valid_in && other_error_in) || multi_resp_in || 
                    ( burst_counter && burst_control_changed ) )
                    next_state  = STATE_ERROR;
                else if ( other_end_in && !burst_counter )
                    next_state  = STATE_TRANS_IDLE;
                else if ( burst_counter && other_delay_in)
                    next_state  = STATE_TRANS_BUSY;
                else if ( !burst_counter )
                    next_state  =  STATE_TRANS_NONSEQ;
                else
                    next_state = STATE_TRANS_SEQ;
                    
            end


            default: begin
                next_state = STATE_RST;
            end
        
        endcase
    end

end



//////////////////////////////////////Sequential logic//////////////////////////////////////////////////

/*get next state*/
always @(negedge ahb_clk_in  or negedge ahb_rstn_in) begin

    if (!ahb_rstn_in)
        ahb_state <=  STATE_RST;
    else
        ahb_state <= next_state;
end


/*data control*/
always @(posedge ahb_clk_in) begin

        case (ahb_state)
            STATE_RST: begin
                ahb_addr_out <= 0;
                ahb_burst_out <= 0;
                ahb_size_out <= 0;
                ahb_strb_out <= 0;
                ahb_trans_out <= 0;
                ahb_wdata_out <= 0;
                ahb_write_out <= 0;
                
                other_burst <= 0;
                other_error_out <= 0;
                other_ready_out <= 0;
                other_rdata_out <= 0;

                busy_2_seq  <= 0;
                trans_unready <= 0;
            end


            STATE_TRANS_IDLE: begin
                busy_2_seq  <= 0;

                other_ready_out  <= multi_ready_in? 1'd1 : 1'd0;
                other_error_out  <= multi_resp_in? 1'd1 : 1'd0;
                other_rdata_out  <= multi_ready_in? multi_rdata_in: 0;

                if (trans_unready && multi_ready_in)
                    trans_unready <= (trans_unready - 1);
                else
                    trans_unready <=  2'd0;

            end

            STATE_TRANS_BUSY:begin
                busy_2_seq   <= 1;
                ahb_addr_out <= burst_addr;
                burst_counter <= (burst_counter - 1);

                ahb_wdata_out <= multi_ready_in && ahb_write_out ? other_wdata_in: 0;
                other_ready_out  <= multi_ready_in? 1'd1 : 1'd0;
                other_error_out  <= multi_resp_in? 1'd1 : 1'd0;
                other_rdata_out  <= other_error_out? multi_rdata_in: 0;

                if (trans_unready && multi_ready_in)
                    trans_unready <= (trans_unready - 1);
                else
                    trans_unready <=  2'd0;

            end

            STATE_TRANS_NONSEQ:begin
                ahb_addr_out <= other_addr_in;
                ahb_burst_out <= other_burst_in;
                ahb_size_out <= other_size_in;
                ahb_strb_out <= other_strb_in;
                ahb_trans_out <= AHB_TRANS_NONSEQ;
                ahb_write_out <= other_size_in;

                busy_2_seq  <= 0;
                trans_unready <= (trans_unready + 1);
                other_burst <= other_burst_in;

                ahb_wdata_out <= multi_ready_in && ahb_write_out ? other_wdata_in: 0;
                other_ready_out  <= multi_ready_in? 1'd1 : 1'd0;
                other_error_out  <= multi_resp_in? 1'd1 : 1'd0;
                other_rdata_out  <= other_error_out? multi_rdata_in: 0;

                if (trans_unready && multi_ready_in)
                    trans_unready <= (trans_unready - 1);
                else
                    trans_unready <=  2'd0;
                
            end

            STATE_TRANS_SEQ:begin
                if (busy_2_seq)
                    busy_2_seq <= 1'd0;
                else if (burst_counter)
                    ahb_addr_out <= burst_addr;
                else
                    ahb_addr_out <= ahb_addr_out;

                ahb_wdata_out <= multi_ready_in && ahb_write_out ? other_wdata_in: 0;
                
                other_ready_out  <= multi_ready_in? 1'd1 : 1'd0;
                other_error_out  <= multi_resp_in? 1'd1 : 1'd0;
                other_rdata_out  <= other_error_out? multi_rdata_in: 0;

                if (trans_unready && multi_ready_in)
                    trans_unready <= (trans_unready - 1);
                else
                    trans_unready <=  2'd0;
                
            end


            STATE_ERROR:begin
                other_error_out <= 1'd1;
                other_ready_out <= 1'd1;
                ahb_addr_out    <= 1'd0;

            end


            default: ;

        endcase

end


assign  burst_control_changed = (other_burst_in != ahb_burst_out) || (other_size_in != ahb_size_out) ||
                              (other_prot_in != ahb_prot_out)? 1'd1: 1'd0;

assign  cur_burst_incr = ( other_burst_in == AHB_BURST_INCR )? 1'd1: 1'd0 ;

assign  next_burst_incr = ( other_burst_in == AHB_BURST_INCR )?1'd1:1'd0;

assign size_valid = (2 << (other_size_in + 3)) > AHB_DATA_WIDTH ? 1'd0 : 1'd1;


assign other_clk_out =  ahb_clk_in;


endmodule

