

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

`define  SIMV

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

    `ifdef  SIMV
        output [2:0]  other_burst_out,
    `endif

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
localparam  STATE_RST               =   3'd0;
localparam  STATE_TRANS_IDLE        =   3'd1;
localparam  STATE_TRANS_BUSY        =   3'd2;
localparam  STATE_TRANS_NONSEQ      =   3'd3;
localparam  STATE_TRANS_SEQ         =   3'd4;
localparam  STATE_ERROR             =   3'd5;



reg  [2:0]  ahb_state;
reg  [2:0]  next_state;



reg  [3:0]  burst_counter;
reg  busy_2_seq;
reg  [AHB_ADDR_WIDTH -1: 0]  burst_next_addr;
reg  [2:0]  cur_burst;
reg  [2:0]  next_burst;
reg  [AHB_ADDR_WIDTH -1: 0]  trans_addr;
reg  [1:0]  trans_unready;
reg  [$clog2(AHB_WAIT_TIMEOUT) -1: 0]  wait_counter;




wire  add_new_trans;
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
wire  ready_timeout;


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
        default:   get_len = 0;
    endcase
endfunction



/*get next burst addr*/
always @(*) begin

    burst_next_addr  =  0;
    if (!cur_burst || !burst_counter)
        burst_next_addr  =  0;
    else if(cur_burst[0])
        burst_next_addr  =  addr_next;
    else begin
        case(cur_burst)
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
        next_state       =    STATE_RST;
    end
    else begin
        case (ahb_state)
            STATE_RST:begin
                if (!ahb_sel_in)
                    next_state          =   STATE_RST;
                else  if (  !size_valid ||  !next_trans_nonseq || !addr_valid) 
                    next_state          =   STATE_ERROR;
                else
                    next_state          =   STATE_TRANS_NONSEQ;
            end

            STATE_TRANS_IDLE:begin
                if ( (!ahb_sel_in && trans_unready) || (ahb_sel_in && (next_trans_busy || next_trans_seq ))
                        ||  (  trans_unready  &&  ready_timeout ) )
                    next_state            =     STATE_ERROR;
                else if (!ahb_sel_in)
                    next_state            =     STATE_RST;
                else if (next_trans_nonseq)
                    next_state            =     STATE_TRANS_NONSEQ;
                else
                    next_state            =     STATE_TRANS_IDLE;
            end    

            STATE_TRANS_BUSY:begin
                if ( (!cur_burst_incr &&  ( !ahb_sel_in || burst_changed ||  trans_changed  || next_trans_idle 
                        || next_trans_nonseq || !burst_counter ) ) || (next_trans_busy && trans_changed) 
                        ||  (  trans_unready  &&  ready_timeout ) )
                        next_state                  =    STATE_ERROR;
                else  if (!ahb_sel_in)
                        next_state                  =    STATE_RST;
                else  if (next_trans_busy)
                        next_state                  =    STATE_TRANS_BUSY;
                else  if (next_trans_idle)
                        next_state                  =    STATE_TRANS_IDLE;
                else  if (next_trans_nonseq)
                        next_state                  =    STATE_TRANS_NONSEQ;
                else
                        next_state                  =    STATE_TRANS_SEQ;
            end

            STATE_TRANS_NONSEQ:begin
                if (!ahb_sel_in  || ( !cur_burst &&  (next_trans_busy || next_trans_seq) ) ||
                    ( !cur_burst_incr  && ( next_trans_idle ||next_trans_nonseq) ) ||  
                    (  trans_unready  &&  ready_timeout )  )
                    next_state              =   STATE_ERROR;
                else  if (next_trans_busy)
                        next_state                  =    STATE_TRANS_BUSY;
                else  if (next_trans_idle)
                        next_state                  =    STATE_TRANS_IDLE;
                else  if (next_trans_nonseq)
                        next_state                  =    STATE_TRANS_NONSEQ;
                else
                        next_state                  =    STATE_TRANS_SEQ;

            end

            STATE_TRANS_SEQ:begin
                if ( !ahb_sel_in  || !cur_burst || ( (next_trans_idle || next_trans_nonseq)  && burst_counter  ) || 
                ( !burst_counter && ( next_trans_seq || next_trans_busy ) && !cur_burst_incr ) 
                ||  (  trans_unready  &&  ready_timeout ) )
                    next_state              =   STATE_ERROR;
                else  if (next_trans_busy)
                        next_state                  =    STATE_TRANS_BUSY;
                else  if (next_trans_idle)
                        next_state                  =    STATE_TRANS_IDLE;
                else  if (next_trans_nonseq)
                        next_state                  =    STATE_TRANS_NONSEQ;
                else
                        next_state                  =    STATE_TRANS_SEQ;
            end


            STATE_ERROR: next_state  =  trans_unready[1] ?  STATE_ERROR:  STATE_RST;

            default:begin
                next_state         =    STATE_RST ;
            end

        endcase

    end

end



//////////////////////////////////////Sequential logic//////////////////////////////////////////////////

/*get next state*/
always @(negedge ahb_clk_in or negedge ahb_rstn_in) begin
    if (!ahb_rstn_in)
        ahb_state    <=    STATE_RST;
    else
        ahb_state    <=    next_state;
end


/*------------address control-------------*/
always @(posedge ahb_clk_in  or  negedge ahb_rstn_in) begin
    if (!ahb_rstn_in) begin
        burst_counter          <=   0;
        busy_2_seq             <=   0;
        cur_burst              <=   0;
        next_burst             <=   0;
        other_addr_out         <=   0;
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
        wait_counter           <=   0;
    end
    else  begin
        case (ahb_state)
            STATE_RST: begin
                burst_counter          <=   0;
                busy_2_seq             <=   0;
                cur_burst              <=   0;
                next_burst             <=   0;
                other_addr_out         <=   0;
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
                wait_counter           <=   0;

            end


            STATE_TRANS_IDLE: begin
                if (trans_unready  && other_ready_in )
                    trans_unready       <=  (trans_unready - 1);
                else
                    trans_unready       <=  trans_unready;

                if (trans_unready[1] && other_ready_in)
                    wait_counter        <=  wait_counter;
                else  if (other_ready_in)
                    wait_counter        <=  0;
                else
                    wait_counter        <=  (wait_counter + 1);

                busy_2_seq              <=  0;

                other_sel_out           <=  trans_unready? 1:  0;
                
            end

            STATE_TRANS_BUSY: begin
                if (trans_unready  && other_ready_in )
                    trans_unready       <=  (trans_unready - 1);
                else
                    trans_unready       <=  trans_unready;

                if (trans_unready[1] && other_ready_in)
                    wait_counter        <=  wait_counter;
                else  if (other_ready_in)
                    wait_counter        <=  0;
                else
                    wait_counter        <=  (wait_counter + 1);

                busy_2_seq              <=  1;
                
            end


            STATE_TRANS_NONSEQ: begin

                busy_2_seq         <=   0;

                cur_burst          <=   add_new_trans? ahb_burst_in : cur_burst;
                other_addr_out     <=   add_new_trans? ahb_addr_in: other_addr_out;
                other_sel_out      <=   1;
                other_size_out     <=   add_new_trans? ahb_size_in: other_size_out;
                other_write_out    <=   add_new_trans? ahb_write_in: other_write_out;

                `ifdef  AHB_PROT
                    other_prot_out     <=    add_new_trans? ahb_prot_in:  other_prot_out;
                `endif
                `ifdef  AHB_WSTRB
                    other_strb_out     <=    add_new_trans? ahb_strb_in: other_strb_out;
                `endif

                burst_counter          <=    add_new_trans?  trans_len: burst_counter;

            end

            STATE_TRANS_SEQ:begin
        
                other_addr_out      <=   other_ready_in?  burst_next_addr: other_addr_out;

                burst_counter       <=   cur_burst_incr || !other_ready_in?  burst_counter: (burst_counter -  1);
            end
                
            default: ;
        endcase

    end

end


/*---------------data transfer -------------*/
always @(posedge ahb_clk_in  or  negedge ahb_rstn_in ) begin
    if (!ahb_rstn_in) begin
        other_wdata_out         <=    0;
        ahb_rdata_out           <=    0;
        ahb_ready_out           <=    0;
        ahb_resp_out            <=    0;
    end
    else begin
        case (ahb_state)
            STATE_RST: begin
                other_wdata_out         <=    0;
                ahb_rdata_out           <=    0;
                ahb_ready_out           <=    0;
                ahb_resp_out            <=    0;
            end

            STATE_TRANS_IDLE  || STATE_TRANS_BUSY || STATE_TRANS_NONSEQ
                ||  STATE_TRANS_SEQ: begin
                other_wdata_out         <=    !other_write_out || other_error_in ? 0:  ahb_wdata_in;
                ahb_rdata_out           <=    other_write_out  || other_error_in ? 0:  other_rdata_in;
                ahb_ready_out           <=    other_ready_in;
                ahb_resp_out            <=    other_error_in;
            end

            STATE_ERROR: begin
                other_wdata_out         <=    0;
                ahb_rdata_out           <=    0;
                ahb_ready_out           <=    trans_unready[1]? 0:  1;
                ahb_resp_out            <=    1;
            end

            default: begin
                other_wdata_out         <=    0;
                ahb_rdata_out           <=    0;
                ahb_ready_out           <=    trans_unready[1]? 0:  1;
                ahb_resp_out            <=    1;
            end
        endcase

    end

end






assign  add_new_trans  =  (other_ready_in || !trans_unready[1] );
assign  addr_aligned  =  ( ( ahb_addr_in & size_mask ) & size_byte )?  0: 1;
assign  addr_changed  = ( burst_next_addr !=  ahb_addr_in );
assign  addr_cross_bound  =  (addr_other_end[11:10]  != ahb_addr_in[11:10] );
assign  addr_other_end  =  ( ahb_addr_in + (size_byte << trans_len) );
assign  addr_next  =  ( other_addr_out + ahb_size_byte );
assign  ahb_size_byte  =  ( 1 <<  other_size_out);
assign  addr_valid  =  ( addr_aligned || !addr_cross_bound );
assign  burst_changed  =  ( ahb_burst_in  !=  cur_burst );

assign  cur_burst_incr = ( cur_burst == AHB_BURST_INCR ) ;


`ifdef  SIMV
    assign  other_burst_out  =  cur_burst;
`endif


assign next_trans_idle   =  (ahb_trans_in == AHB_TRANS_IDLE);
assign next_trans_busy   =  (ahb_trans_in == AHB_TRANS_BUSY);
assign next_trans_nonseq  = (ahb_trans_in == AHB_TRANS_NONSEQ);
assign next_trans_seq  =  (ahb_trans_in == AHB_TRANS_SEQ);


`ifdef  AHB_PROT
    assign  prot_changed  =  ( other_prot_out  != ahb_prot_in );
`else
    assign  prot_changed  =  0;
`endif
`ifdef  AHB_WSTRB
    assign  strb_changed  =  ( other_strb_out  != ahb_strb_in );
`else
    assign  strb_changed  =  0;
`endif



assign  ready_timeout  =  (wait_counter ==  AHB_WAIT_TIMEOUT);

assign  size_byte   =  ( 1 << ahb_size_in );
assign  size_changed  =  ( ahb_size_in  !=  other_size_out );
assign  size_mask   =  ( size_byte  - 1 );
assign  size_valid  =  ( size_byte  << 3 ) > AHB_DATA_WIDTH ? 0: 1;


assign  trans_changed  =  addr_changed || burst_changed || prot_changed 
                        || size_changed || strb_changed;
assign  trans_len  =  get_len(cur_burst);


assign  next_burst_incr = ( ahb_burst_in == AHB_BURST_INCR ) ;



assign  other_clk_out =  ahb_clk_in;

assign   wrap4_bound   =  ( addr_next & ( ( ahb_size_byte << 2) - 1))?  0:  1;
assign   wrap8_bound   =  ( addr_next & ( ( ahb_size_byte << 3) - 1))?  0:  1;
assign   wrap16_bound  =  ( addr_next & ( ( ahb_size_byte << 4) - 1))?  0:  1;



endmodule //ahb_slave_if


