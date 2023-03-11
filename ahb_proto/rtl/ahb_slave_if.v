

/*************************************************************************
* Module Name:     ahb_slave_if
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     AHB slave interface.
*                  Address and data bus widths are configurable using APB_ADDR_WIDTH
*                  and APB_DATA_WIDTH parameters.
*
* Version:         0.1
******************************************************************************/

module ahb_slave_if #(  parameter   AHB_DATA_WIDTH    = 32,
                        parameter   AHB_ADDR_WIDTH    = 32,
                        parameter   AHB_WAIT_TIMEOUT  =  6
                        )
(



    input   ahb_clk_in,
    input   ahb_rstn_in,

    input   [AHB_ADDR_WIDTH -1:0]  ahb_addr_in,
    input   [2:0]  ahb_burst_in,
    output  [AHB_DATA_WIDTH -1:0]  ahb_rdata_out,
    output  ahb_ready_out,    
    output  ahb_resp_out,
    input   ahb_sel_in,
    input   [2:0]  ahb_size_in,

    `ifdef  AHB_PROT
        input  [3:0]  ahb_prot_in,
    `endif
    `ifdef  AHB_WSTRB
        input  [(AHB_DATA_WIDTH /8) -1:0]  ahb_strb_in,        
    `endif

    input   [1:0]  ahb_trans_in,
    input   [AHB_DATA_WIDTH -1: 0]  ahb_wdata_in,
    input   ahb_write_in,


    output  [AHB_ADDR_WIDTH -1:0]  other_addr_out,
    output  other_clk_out,
    input   other_error_in,
    output  other_error_out,
    input   [AHB_DATA_WIDTH -1: 0]  other_rdata_in,
    input   other_ready_in,
    output  other_sel_out,
    output  [2:0]  other_size_out,

    `ifdef  AHB_PROT
        output  [3:0]  other_prot_out,
    `endif
    `ifdef  AHB_WSTRB
        output  [(AHB_DATA_WIDTH /8) -1:0]  other_strb_out,    
    `endif

    output  [AHB_DATA_WIDTH -1:0]  other_wdata_out,
    output  other_write_out
);




/*ahb trans type*/
localparam  AHB_TRANS_IDLE = 2'd0;
localparam  AHB_TRANS_BUSY = 2'd1;
localparam  AHB_TRANS_NONSEQ = 2'd2;
localparam  AHB_TRANS_SEQ = 2'd3;


/*ahb burst type*/
localparam  AHB_BURST_SINGLE   =  3'd0;
localparam  AHB_BURST_INCR     =  3'd1;
localparam  AHB_BURST_WRAP4    =  3'd2;
localparam  AHB_BURST_INCR4    =  3'd3;
localparam  AHB_BURST_WRAP8    =  3'd4;
localparam  AHB_BURST_INCR8    =  3'd5;
localparam  AHB_BURST_WRAP16   =  3'd6;
localparam  AHB_BURST_INCR16   =  3'd7;


/*ahb slave state*/
localparam  STATE_RST               =   0;
localparam  STATE_TRANS_IDLE        =   1;
localparam  STATE_TRANS_BUSY        =   2;
localparam  STATE_TRANS_NONSEQ      =   3;
localparam  STATE_TRANS_SEQ         =   4;
localparam  STATE_ERROR             =   5;



reg  [5:0]  ahb_state;
reg  [5:0]  next_state;



reg  [3:0]  burst_counter;
reg  busy_2_seq;
reg  [$log2(AHB_WAIT_TIMEOUT) -1: 0]  wait_timeout;
reg  [1:0]  trans_unready;
reg  last_write;
reg  [AHB_ADDR_WIDTH -1: 0]  burst_next_addr;
reg  [AHB_ADDR_WIDTH -1: 0]  trans_addr;



reg  [2:0] ahb_burst;



wire  next_burst_incr;
wire  next_trans_idle;
wire  next_trans_busy;
wire  next_trans_nonseq;
wire  next_trans_seq;
wire  burst_addr_valid;

wire cur_burst_changed;
wire size_valid;



///////////////////////////Combinational logic//////////////////////////////////////////////////

/*get next burst addr*/
always @(*) begin
    if (!ahb_burst || burst_counter)
        burst_addr = 0;
    else if(ahb_burst[0])
        burst_addr = other_addr_out + ( 2 << other_size_out);
    else begin
        case(ahb_burst)
        AHB_BURST_WRAP4: burst_addr = (other_addr_out + (2 << other_size_out)) & (( 2 << (other_size_out + 2) ) - 1)?
                             other_addr_out + ( 2 << other_size_out): 
                             other_addr_out - (6 << other_size_out);
        AHB_BURST_WRAP8: burst_addr = (other_addr_out + (2 << other_size_out)) & (( 2 << (other_size_out + 3) ) - 1)?
                             other_addr_out + ( 2 << other_size_out): 
                             other_addr_out -  (14 << other_size_out);
        AHB_BURST_WRAP16: burst_addr = (other_addr_out + (2 << other_size_out)) & (( 2 << (other_size_out + 4) ) - 1)?
                             other_addr_out + ( 2 << other_size_out): 
                             other_addr_out - ( 30 << other_size_out);
        default: burst_addr = 0;
            

        endcase
    end
    
end




/*FSM*/
always @(*) begin

    if (!ahb_rstn_in)begin
        next_state = STATE_RST;
    end
    else begin
        case (ahb_state)
            STATE_RST:begin
                if (decoder_sel_in && ( !size_valid || !next_trans_nonseq) )
                    next_state = STATE_ERROR;
                else if (!decoder_sel_in)
                    next_state = STATE_RST;
                else
                    next_state = STATE_TRANS_NONSEQ;
            end

            STATE_TRANS_IDLE:begin
                if ( (!decoder_sel_in && last_ready) ||  !size_valid || next_trans_busy
                    || ( next_trans_seq &&  !burst_counter ) || ( next_trans_nonseq && burst_counter) )
                    next_state = STATE_ERROR;
                else if (!decoder_sel_in )
                    next_state = STATE_RST;
                else begin
                    case(ahb_trans_in)
                    AHB_TRANS_IDLE: next_state = STATE_TRANS_IDLE;
                    AHB_TRANS_NONSEQ:  next_state = STATE_TRANS_NONSEQ;
                    AHB_TRANS_SEQ:  next_state = STATE_TRANS_SEQ;
                    default: next_state = STATE_TRANS_IDLE;
                    endcase

                end
                
            end    

            STATE_TRANS_BUSY:begin
                if (!decoder_sel_in || !size_valid || ( !next_trans_busy && !next_trans_seq
                 && !next_burst_incr ) || cur_burst_changed || !burst_addr_valid )
                    next_state = STATE_ERROR;
                else if (next_burst_incr)begin
                    case(ahb_trans_in)
                    AHB_TRANS_IDLE:     next_state = STATE_TRANS_IDLE;
                    AHB_TRANS_BUSY:     next_state = STATE_TRANS_BUSY;
                    AHB_TRANS_NONSEQ:   next_state = STATE_TRANS_NONSEQ;
                    AHB_TRANS_SEQ:      next_state = STATE_TRANS_SEQ;
                    endcase
                end
                else
                    next_state = next_trans_busy?STATE_TRANS_BUSY:STATE_TRANS_SEQ;
                    
            end

            STATE_TRANS_NONSEQ:begin
                if ( !decoder_sel_in && !last_ready || !size_valid  || (next_trans_busy && !ahb_burst) || 
                   (next_trans_idle && ( burst_counter || ahb_burst )) || 
                   (next_trans_nonseq && (burst_counter || ahb_burst )) || (next_trans_seq && 
                   (!burst_counter || !ahb_burst ) ))
                    next_state = STATE_ERROR;
                else if (!decoder_sel_in)
                    next_state = STATE_RST;
                else begin
                    case(ahb_trans_in)
                    AHB_TRANS_IDLE:     next_state = STATE_TRANS_IDLE;
                    AHB_TRANS_BUSY:     next_state = STATE_TRANS_BUSY;
                    AHB_TRANS_NONSEQ:   next_state = STATE_TRANS_NONSEQ;
                    AHB_TRANS_SEQ:      next_state = STATE_TRANS_SEQ;
                    endcase
                end

            end

            STATE_TRANS_SEQ:begin
                if ( !decoder_sel_in || !size_valid || ((next_trans_idle || next_trans_nonseq)  && burst_counter  ) || 
                (next_trans_seq && (!burst_counter || !burst_addr_valid )) )
                    next_state = STATE_ERROR;
                else begin
                    case(ahb_trans_in)
                    AHB_TRANS_IDLE:     next_state = STATE_TRANS_IDLE;
                    AHB_TRANS_BUSY:     next_state = STATE_TRANS_BUSY;
                    AHB_TRANS_NONSEQ:   next_state = STATE_TRANS_NONSEQ;
                    AHB_TRANS_SEQ:      next_state = STATE_TRANS_SEQ;
                    endcase
                end

            end

            default:begin
                next_state = STATE_RST;
            end

        endcase

    end

end



//////////////////////////////////////Sequential logic//////////////////////////////////////////////////

/*get next state*/
always @(negedge ahb_clk_in  or negedge ahb_rstn_in) begin

    if (!ahb_rstn_in)
        ahb_state <= STATE_RST;
    else
        ahb_state  <= next_state;

end


/*data control*/
always @(posedge ahb_clk_in or negedge ahb_rstn_in ) begin

    if (!ahb_rstn_in) begin
                ahb_burst              <= 0;
                burst_counter          <= 0;
                last_ready             <=  1;
                other_addr_out         <=  0;
                other_sel_out          <=  0;
                other_size_out         <=  0;
                other_wdata_out        <=  0;
                other_write_out        <=  0;
                rst_2_trans            <= 1;
    end
    else begin
        case (ahb_state)
            STATE_RST: begin
                ahb_burst              <= 0;
                burst_counter          <= 0;
                last_ready             <=  1;
                other_addr_out         <=  0;
                other_sel_out          <=  0;
                other_size_out         <=  0;
                other_wdata_out        <=  0;
                other_write_out        <=  0;
                rst_2_trans            <= 1;
            end


            STATE_TRANS_IDLE: begin
                if (multi_readyout_out)
                    last_ready <= 1;
                else
                    last_ready <= 0;
            end

            STATE_TRANS_BUSY: begin
                if (multi_readyout_out)
                    last_ready <= 1;
                else
                    last_ready <= 0;
            end

            STATE_TRANS_NONSEQ: begin

                rst_2_trans <= 0;
                if ( rst_2_trans || last_ready) begin
                    ahb_burst       <= ahb_burst_in;
                    other_addr_out  <= ahb_addr_in;
                    other_sel_out   <= decoder_sel_in;
                    other_size_out  <= ahb_size_in;
                    other_strb_out  <= ahb_strb_in;
                    other_wdata_out <= ahb_write_in?ahb_wdata_in:0;
                    other_write_out <= ahb_write_in;
            
                    if (ahb_burst_in) begin
                        if (ahb_burst_in >= 3'd6)
                            burst_counter <= 4'd15;
                        else if (ahb_burst_in >= 3'd4)
                            burst_counter <= 4'd7;
                        else
                            burst_counter <= 4'd3;
                    end
                    else
                        burst_counter <= 4'd0;
                end
            end

            STATE_TRANS_SEQ:begin
        
                if ((ahb_burst == AHB_BURST_INCR) && last_ready)
                    other_addr_out <= burst_addr;
                else
                    other_addr_out <= other_addr_out;
                
                other_wdata_out <= ahb_write_in? ahb_wdata_in:0;
                burst_counter <= (burst_counter - 4'd1);
            end

            STATE_ERROR:begin
                other_error_out <= 1'd1;
            end
                
      
            default: ;

        endcase        

    end

end


assign  burst_addr_valid = (burst_addr == ahb_trans_in)?1'd1:1'd0;
assign  cur_burst_changed =  (ahb_burst_in != ahb_burst)?1'd1:1'd0;
assign  next_burst_incr = ( ahb_burst_in == AHB_BURST_INCR )?1'd1:1'd0;

assign next_trans_idle = (ahb_trans_in == AHB_TRANS_IDLE)?1'd1:1'd0;
assign next_trans_busy = (ahb_trans_in == AHB_TRANS_BUSY)?1'd1:1'd0;
assign next_trans_nonseq = (ahb_trans_in == AHB_TRANS_NONSEQ)?1'd1:1'd0;
assign next_trans_seq = (ahb_trans_in == AHB_TRANS_SEQ)?1'd1:1'd0;


assign multi_rdata_out = other_write_out?32'd0:other_rdata_in;
assign multi_readyout_out = other_ready_in || (ahb_state == STATE_ERROR)? 1'd1:1'd0;
assign multi_resp_out = ( !other_error_in && (ahb_state != STATE_ERROR)) || (ahb_state == STATE_TRANS_IDLE)?1'd0:1'd1;

assign other_clk_out =  ahb_clk_in;

assign size_valid = (2 << (ahb_size_in + 3)) > AHB_DATA_WIDTH ? 1'd1:1'd0;



endmodule //ahb_slave_if

