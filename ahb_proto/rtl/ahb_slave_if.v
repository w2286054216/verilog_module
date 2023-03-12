

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
    output  reg  [AHB_DATA_WIDTH -1:0]  ahb_rdata_out,
    output  reg  ahb_ready_out,    
    output  reg  ahb_resp_out,
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


    output  reg  [AHB_ADDR_WIDTH -1:0]  other_addr_out,
    output  other_clk_out,
    input   other_error_in,
    output  reg  other_error_out,
    input   [AHB_DATA_WIDTH -1: 0]  other_rdata_in,
    input   other_ready_in,
    output  reg  other_sel_out,
    output  reg  [2:0]  other_size_out,

    `ifdef  AHB_PROT
        output  reg  [3:0]  other_prot_out,
    `endif
    `ifdef  AHB_WSTRB
        output  reg  [(AHB_DATA_WIDTH /8) -1:0]  other_strb_out,    
    `endif

    output  reg  [AHB_DATA_WIDTH -1:0]  other_wdata_out,
    output  reg  other_write_out
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


reg  [2:0] ahb_burst;
reg  [3:0]  burst_counter;
reg  busy_2_seq;
reg  [AHB_ADDR_WIDTH -1: 0]  burst_next_addr;
reg  [1:0]  other_burst;
reg  [AHB_ADDR_WIDTH -1: 0]  trans_addr;
reg  [1:0]  trans_unready;
reg  [$clog2(AHB_WAIT_TIMEOUT) -1: 0]  wait_timeout;





wire  addr_aligned;
wire  addr_changed;
wire  addr_cross_bound;
wire  [AHB_ADDR_WIDTH -1: 0]  addr_next;
wire  [AHB_ADDR_WIDTH -1: 0]  addr_other_end;
wire  [7:0]  ahb_size_byte;
wire  addr_valid;
wire  burst_changed;
wire  cur_burst_incr;
wire  prot_changed;
wire  size_changed;
wire  size_valid;
wire  [ 7:0 ]  size_byte;
wire  [ 6:0 ]  size_mask;
wire  strb_changed;
wire  trans_changed;
wire  [2:0]  trans_len;
wire  wrap4_bound;
wire  wrap8_bound;
wire  wrap16_bound;



wire  next_burst_incr;
wire  next_trans_idle;
wire  next_trans_busy;
wire  next_trans_nonseq;
wire  next_trans_seq;
wire  burst_addr_valid;



///////////////////////////Combinational logic//////////////////////////////////////////////////

function  [2:0] get_len(input [2: 0] burst);
    case(burst)
        AHB_BURST_SINGLE || AHB_BURST_INCR:  get_len  =  0;
        AHB_BURST_INCR4   ||  AHB_BURST_WRAP4:   get_len  =  2;
        AHB_BURST_INCR8   ||  AHB_BURST_WRAP8:   get_len  =  3;
        AHB_BURST_INCR16  ||  AHB_BURST_WRAP16:  get_len  =  4;
    endcase
endfunction



/*get next burst addr*/
always @(*) begin

    burst_next_addr  =  0;
    if (!ahb_burst || !burst_counter)
        burst_next_addr  =  0;
    else if(ahb_burst[0])
        burst_next_addr  =  addr_next;
    else begin
        case(ahb_burst)
            AHB_BURST_WRAP4: burst_next_addr   =  !wrap4_bound?  addr_next: 
                                        other_addr_out - ( 3 << other_size_out );
            AHB_BURST_WRAP8: burst_next_addr   =  !wrap8_bound?  addr_next: 
                                        other_addr_out -  ( 7 << other_size_out );
            AHB_BURST_WRAP16: burst_next_addr  =  !wrap16_bound? addr_next:
                                        other_addr_out - ( 15 << other_size_out );
            default: burst_next_addr = 0;
            
        endcase
    end
    
end


/*FSM*/
always @(*) begin
    if (!ahb_rstn_in)begin
        next_state[STATE_RST]  =  1'd1;
    end
    else begin
        case (1'd1)
            ahb_state[STATE_RST]:begin
                if (!ahb_sel_in)
                    next_state[STATE_RST]  =   1'd1;
                else  if (  !size_valid ||  ( ahb_trans_in != AHB_TRANS_NONSEQ) || !addr_valid) 
                    next_state[STATE_ERROR] =  1'd1;
                else
                    next_state = STATE_TRANS_NONSEQ;
            end

            ahb_state[STATE_TRANS_IDLE]:begin
                if ( (!ahb_sel_in && trans_unready) || (ahb_sel_in && (next_trans_busy || next_trans_seq )))
                    next_state[STATE_ERROR]  =  1'd1;
                else if (!ahb_sel_in)
                    next_state[STATE_RST]  =  1'd1;
                else begin
                    case(ahb_trans_in)
                        AHB_TRANS_NONSEQ:  next_state[STATE_TRANS_NONSEQ]  =  1'd1;
                    default: next_state[STATE_TRANS_IDLE]  =  1'd1;
                    endcase
                end
                
            end    

            ahb_state[STATE_TRANS_BUSY]:begin
                if (!ahb_sel_in || burst_changed || ((next_trans_idle || next_trans_nonseq || !burst_counter ) 
                    && !cur_burst_incr) ||  trans_changed  || (ahb_addr_in != burst_next_addr) )
                    next_state[STATE_ERROR]  =  1'd1;
                else if (next_burst_incr)begin
                    case(ahb_trans_in)
                        AHB_TRANS_IDLE:     next_state[STATE_TRANS_IDLE]    =   1'd1;
                        AHB_TRANS_BUSY:     next_state[STATE_TRANS_BUSY]    =   1'd1;
                        AHB_TRANS_NONSEQ:   next_state[STATE_TRANS_NONSEQ]  =   1'd1;
                        AHB_TRANS_SEQ:      next_state[STATE_TRANS_SEQ]     =   1'd1;
                    endcase
                end
            end

            ahb_state[STATE_TRANS_NONSEQ]:begin
                if (!ahb_sel_in  || ((next_trans_busy || next_trans_seq) && !ahb_burst) ||
                    ( ( next_trans_idle ||next_trans_nonseq) && ahb_burst ) || 
                    ( ( next_trans_seq || next_trans_busy) && !ahb_burst  )  )
                    next_state[STATE_ERROR]  =  1'd1;
                else begin
                    case(ahb_trans_in)
                        AHB_TRANS_IDLE:     next_state[STATE_TRANS_IDLE]    =  1'd1;
                        AHB_TRANS_BUSY:     next_state[STATE_TRANS_BUSY]    =  1'd1;
                        AHB_TRANS_NONSEQ:   next_state[STATE_TRANS_NONSEQ]  =  1'd1;
                        AHB_TRANS_SEQ:      next_state[STATE_TRANS_SEQ]     =  1'd1;
                    endcase
                end

            end

            ahb_state[STATE_TRANS_SEQ]:begin
                if ( !ahb_sel_in || ((next_trans_idle || next_trans_nonseq)  && burst_counter  ) || 
                (next_trans_seq && !burst_counter) ) 
                    next_state[STATE_ERROR]  =  1'd1;
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
                next_state[STATE_RST]  =  1'd1;
            end

        endcase

    end

end



//////////////////////////////////////Sequential logic//////////////////////////////////////////////////

/*get next state*/
always @(negedge ahb_clk_in) begin
    ahb_state  <=   next_state;
end


/*------------address control-------------*/
always @(posedge ahb_clk_in) begin
    case (1'd1)
        ahb_state[STATE_RST]: begin
            ahb_burst              <=   0;
            burst_counter          <=   0;
            busy_2_seq             <=   0;
            other_addr_out         <=   0;
            other_burst            <=   0;
            other_error_out        <=   0;
            other_sel_out          <=   0;
            other_size_out         <=   0;

            `ifdef  AHB_PROT
                other_prot_out     <=   0;
            `endif
            `ifdef  AHB_WSTRB
                other_strb_out     <=   0;
            `endif

            other_write_out        <=   0;

            trans_addr             <=   0;
            trans_unready          <=   0;
            wait_timeout           <=   0;

        end


        ahb_state[STATE_TRANS_IDLE]: begin
            if (trans_unready && (other_error_in || other_ready_in))
                trans_unready       <=  (trans_unready - 1);
            else
                trans_unready       <=  trans_unready;
            
        end

        ahb_state[STATE_TRANS_BUSY]: begin
            if (trans_unready && (other_error_in || other_ready_in))
                trans_unready       <=  (trans_unready - 1);
            else
                trans_unready       <=  trans_unready;

            busy_2_seq              <=  1;
            
        end


        ahb_state[STATE_TRANS_NONSEQ]: begin

            busy_2_seq         <=   0;

            ahb_burst          <=   ahb_burst_in;
            other_addr_out     <=   ahb_addr_in;
            other_sel_out      <=   1;
            other_size_out     <=   ahb_size_in;
            other_wdata_out    <=   ahb_write_in?ahb_wdata_in:0;
            other_write_out    <=   ahb_write_in;

            `ifdef  AHB_PROT
                other_prot_out     <=    ahb_prot_in;
            `endif
            `ifdef  AHB_WSTRB
                other_strb_out     <=    ahb_strb_in;
            `endif

            if (ahb_burst_in) begin
                if (ahb_burst_in >= 3'd6)
                    burst_counter           <=    4'd15;
                else if (ahb_burst_in >= 3'd4)
                    burst_counter           <=    4'd7;
                else
                    burst_counter           <=    4'd3;
            end
            else
                burst_counter               <=    4'd0;

        end

        ahb_state[STATE_TRANS_SEQ]:begin
    
            other_addr_out      <=   burst_next_addr;

            burst_counter           <=   (burst_counter -  1);
        end
            
        default: ;
    endcase
end


/*---------------data transfer -------------*/
always @(posedge ahb_clk_in or negedge ahb_rstn_in ) begin

    case (1'd1)
        ahb_state[STATE_RST]: begin
            other_wdata_out         <=    0;
            ahb_rdata_out           <=    0;
            ahb_ready_out           <=    0;
            ahb_resp_out            <=    0;
        end

        ahb_state[STATE_TRANS_IDLE]  || ahb_state[STATE_TRANS_BUSY] || ahb_state[STATE_TRANS_NONSEQ]
            ||  ahb_state[STATE_TRANS_SEQ]: begin
            other_wdata_out         <=    other_write_out?ahb_wdata_in:  0;
            ahb_rdata_out           <=    0;
            ahb_ready_out           <=    0;
            ahb_resp_out            <=    0;
        end

        ahb_state[STATE_ERROR]: begin
            other_wdata_out         <=    0;
            ahb_rdata_out           <=    0;
            ahb_ready_out           <=    trans_unready[1]? 0:  1;
            ahb_resp_out            <=    1;
        end

        default: ;

    endcase

end





assign next_trans_idle = (ahb_trans_in == AHB_TRANS_IDLE)?1'd1:1'd0;
assign next_trans_busy = (ahb_trans_in == AHB_TRANS_BUSY)?1'd1:1'd0;
assign next_trans_nonseq = (ahb_trans_in == AHB_TRANS_NONSEQ)?1'd1:1'd0;
assign next_trans_seq = (ahb_trans_in == AHB_TRANS_SEQ)?1'd1:1'd0;

assign  addr_aligned  =  ( ( ahb_addr_in & size_mask ) & size_byte )?  0: 1;
assign  addr_changed  = ( burst_next_addr !=  ahb_addr_in );
assign  addr_cross_bound  =  (addr_other_end[11:10]  != ahb_addr_in[11:10] );
assign  addr_other_end  =  ( ahb_addr_in + (size_byte << trans_len) );
assign  addr_next  =  ( other_addr_out + ahb_size_byte );
assign  ahb_size_byte  =  ( 1 <<  other_size_out);
assign  addr_valid  =  ( addr_aligned || !addr_cross_bound );
assign  burst_changed  =  ( ahb_burst_in  !=  other_burst );

`ifdef  AHB_PROT
    assign  prot_changed  =  ( other_prot_in  != ahb_prot_out );
`else
    assign  prot_changed  =  0;
`endif
`ifdef  AHB_WSTRB
    assign  strb_changed  =  ( other_strb_in  != ahb_strb_out );
`else
    assign  strb_changed  =  0;
`endif


assign  size_byte   =  ( 1 << ahb_size_in );
assign  size_changed  =  ( ahb_size_in  !=  other_size_out );
assign  size_mask   =  ( size_byte  - 1 );
assign  size_valid  =  ( size_byte  << 3 ) > AHB_DATA_WIDTH ? 0: 1;



assign  trans_changed  =  addr_changed || burst_changed || prot_changed 
                        || size_changed || strb_changed;
assign  trans_len  =  get_len(ahb_burst);

assign  cur_burst_incr = ( other_burst == AHB_BURST_INCR )? 1'd1: 1'd0 ;

assign  next_burst_incr = ( ahb_burst_in == AHB_BURST_INCR )?1'd1:1'd0;



assign  other_clk_out =  ahb_clk_in;

assign   wrap4_bound   =  ( addr_next & ( ( ahb_size_byte << 2) - 1))?  0:  1;
assign   wrap8_bound   =  ( addr_next & ( ( ahb_size_byte << 3) - 1))?  0:  1;
assign   wrap16_bound  =  ( addr_next & ( ( ahb_size_byte << 4) - 1))?  0:  1;



endmodule //ahb_slave_if


