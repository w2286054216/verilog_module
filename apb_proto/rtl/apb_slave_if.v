
/**************************************************************************************
* Module Name:     apb_slave_if
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB slave interface.
*                  Address and data bus widths are configurable using APB_ADDR_WIDTH
*                  and APB_DATA_WIDTH parameters.
*
* Version:         0.1
*************************************************************************************/

module  apb_slave_if #( parameter   APB_DATA_WIDTH    = 32,
                        parameter   APB_ADDR_WIDTH    = 32,
                        parameter   TIMEOUT_CYCLE     =  6
                        )
(
    input  apb_clk_in,
    input  apb_rstn_in,


    /*-----------apb bus signal------------*/
    input  [APB_ADDR_WIDTH -1: 0]  apb_addr_in,
    input  apb_penable_in,

    `ifdef  APB_PROT
        input  [2:0]  apb_prot_in,
    `endif

    `ifdef  APB_WSTRB
        input  [(APB_DATA_WIDTH / 8) -1:0]  apb_strb_in,
    `endif

    `ifdef  APB_SLVERR
        input   apb_slverr_in,
        output  apb_slverr_out,
    `endif

    input  apb_psel_in,
    output  reg  [APB_DATA_WIDTH-1:0]  apb_rdata_out,
    output  reg  apb_ready_out,
    input   [APB_DATA_WIDTH-1:0]  apb_wdata_in,
    input   apb_write_in,


    /*--------other module signal------------*/
    output  reg  [APB_ADDR_WIDTH -1: 0]  other_addr_out,
    output  other_clk_out,
    input   other_error_in,
    output  reg  other_error_out,
    input   [APB_DATA_WIDTH-1:0]  other_rdata_in,
    input   other_ready_in,

    `ifdef  APB_PROT
        output  reg  [2:0]  other_prot_out,
    `endif
    `ifdef  APB_WSTRB
        output  reg  [(APB_DATA_WIDTH / 8) -1:0]  other_strb_out,
    `endif

    output  reg  other_sel_out,
    output  reg  [APB_DATA_WIDTH-1:0]  other_wdata_out,
    output  reg  other_write_out

);



/*FSM state definition*/
localparam  STATE_RST       =   0;
localparam  STATE_SETUP     =   1;
localparam  STATE_WAIT      =   2;
localparam  STATE_TRANS     =   3;
localparam  STATE_ERROR     =   4;





reg [TIMEOUT_CYCLE -1: 0]  wait_counter;

reg  [4:0]  apb_state;
reg  [4:0]  next_state;


wire   addr_chagned;
wire   prot_changed;
wire   strb_changed;
wire   wdata_changed;
wire   write_changed;
wire   signal_changed;
wire   wait_timeout;






//////////////////////////////////Combinatorial logic//////////////////////////////////////////


/*FSM state*/
always @(*) begin
    next_state  =  0;
    if (!apb_rstn_in)
        next_state[STATE_RST]  =  1'd1;
    else begin
        case (1'd1)
            apb_state[STATE_RST]:begin
                    if (!apb_psel_in || apb_penable_in)
                        next_state[STATE_RST]    =  1'd1;
                    else
                        next_state[STATE_SETUP]  =  1'd1;
            end

            apb_state[STATE_SETUP]:begin
                if ( !apb_penable_in || !apb_psel_in  || other_error_in || signal_changed )
                    next_state[STATE_ERROR]  =  1'd1;
                else  if (other_ready_in)
                    next_state[STATE_TRANS]  =  1'd1;
                else
                    next_state[STATE_WAIT]   =  1'd1;
            end

            apb_state[STATE_WAIT]:begin
                if ( !apb_penable_in || !apb_psel_in || other_error_in || signal_changed || wait_timeout )
                    next_state[STATE_ERROR]  =  1'd1;
                else  if (other_ready_in)
                    next_state[STATE_TRANS]  =  1'd1;
                else
                    next_state[STATE_WAIT]   =  1'd1;  
            end
            
            default: 
                next_state[STATE_RST]  =  1'd1;

        endcase
        
    end

end





///////////////////////////////////Sequential logic/////////////////////////////////////////////


/*Set apb state*/
always @(negedge apb_clk_in) begin
    apb_state <= next_state;
end


/*Slave transfer data*/
always @( posedge  apb_clk_in  or  negedge  apb_rstn_in ) begin
    if (!apb_rstn_in) begin
        
        `ifdef  APB_SLVERR
            apb_slverr_out    <=  0;
        `endif
        apb_rdata_out       <=  0;
        apb_ready_out       <=  0;

        other_addr_out      <=  0;
        other_error_out     <=  0;

        `ifdef  APB_PROT
            other_prot_out  <=  0;
        `endif
        `ifdef  APB_WSTRB
            other_strb_out  <=  0;
        `endif
        other_sel_out       <=  0;
        other_wdata_out     <=  0;
        other_write_out     <=  0;

        wait_counter        <=  0;


    end
    else begin
        case (1'd1)
            apb_state[STATE_RST]:begin

                `ifdef  APB_SLVERR
                    apb_slverr_out    <=  0;
                `endif
                apb_rdata_out       <=  0;
                apb_ready_out       <=  0;

                other_addr_out      <=  0;
                other_error_out     <=  0;

                `ifdef  APB_PROT
                    other_prot_out  <=  0;
                `endif
                `ifdef  APB_WSTRB
                    other_strb_out  <=  0;
                `endif
                other_sel_out       <=  0;
                other_wdata_out     <=  0;
                other_write_out     <=  0;

                wait_counter        <=  0;
                
            end

            apb_state[STATE_SETUP]:begin
                
                other_addr_out      <=   apb_addr_in;

                `ifdef  APB_PROT
                    other_prot_out      <=   apb_prot_in;
                `endif
                `ifdef  APB_WSTRB
                    other_strb_out      <=   apb_strb_in;
                `endif

                other_write_out      <=   apb_write_in;
                other_sel_out       <=   1;                
                other_wdata_out     <=   apb_wdata_in;
                other_write_out     <=   apb_write_in;

                apb_ready_out       <=   0;

            end

            apb_state[STATE_WAIT]: wait_counter   <=  (wait_counter + 1);

            apb_state[STATE_TRANS]: begin

                `ifdef  APB_SLVERR
                    other_error_out     <=  apb_slverr_in  ||  other_error_in;
                    apb_slverr_out      <=  apb_slverr_in  ||  other_error_in;
                    apb_rdata_out       <=  other_write_out || apb_slverr_in  ||  other_error_in ?
                                                    0: other_rdata_in;
                `else
                    other_error_out     <=  other_error_in;
                    apb_rdata_out       <=  other_write_out  ||  other_error_in ?
                                                    0: other_rdata_in;
                `endif
                

                apb_ready_out       <=  1;
                other_sel_out       <=  0;
            end

            apb_state[STATE_ERROR]:begin
                `ifdef  APB_SLVERR
                    apb_slverr_out       <=  1;
                `endif
                apb_ready_out        <=  1;
                other_error_out      <=  1;
                other_sel_out        <=  0;
                
            end

            default:;
        endcase
    end
    
end



assign  addr_chagned   =  ( other_addr_out  != apb_addr_in);
assign  write_changed  =  ( apb_write_in != other_write_out);
assign  wdata_changed  =  other_write_out && (other_wdata_out != apb_wdata_in);

`ifdef  APB_PROT
assign  prot_changed   =  ( other_prot_out != apb_prot_in );
`else
assign  prot_changed   =  0;
`endif

`ifdef  APB_WSTRB
assign  strb_changed   =  ( other_strb_out != apb_strb_in );
`else
assign  strb_changed   =  0;   
`endif


assign  signal_changed = addr_chagned || write_changed || wdata_changed 
                            || prot_changed || strb_changed;


assign  other_clk_out = apb_clk_in;
assign  wait_timeout  =  (wait_counter == TIMEOUT_CYCLE);



endmodule


