
/**********************************************************************************
* Module Name:     apb_master_if
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB master interface.
*                  Address and data bus widths are configurable using APB_ADDR_WIDTH and APB_DATA_WIDTH
*                  parameters apb_psel width can also be configured using SLAVE_DEVICES.
* Version:         0.1
********************************************************************************/


module  apb_master_if  #(   parameter   APB_DATA_WIDTH  =  32,
                            parameter   APB_ADDR_WIDTH  =  32,
                            parameter   TIMEOUT_CYCLE   =  6
                        )
(
    /*----------apb bus signal-------------*/
    output  reg  [APB_ADDR_WIDTH-1:0]  apb_addr_out,
    input   apb_clk_in,
    output  reg  apb_penable_out,

    `ifdef  APB_PROT
        output  reg  [2:0]  apb_prot_out,
    `endif

    output  reg  apb_psel_out,
    input   [APB_DATA_WIDTH-1:0]  apb_rdata_in,
    input   apb_ready_in,
    input   apb_rstn_in,

    `ifdef  APB_SLVERR
        input   apb_slverr_in,
        output  reg  apb_slverr_out,
    `endif

    `ifdef  APB_WSTRB
        output  reg  [(APB_DATA_WIDTH / 8) -1: 0]  apb_strb_out,
    `endif

    output  reg  [APB_DATA_WIDTH-1:0]  apb_wdata_out,
    output  reg  apb_write_out,



    /*------------other module signal------------*/
    input   [APB_ADDR_WIDTH-1:0]  other_addr_in,
    output  other_clk_out,
    input   other_error_in,
    output  reg  other_error_out,

    `ifdef  APB_PROT
        input   [2:0] other_prot_in,
    `endif

    output  reg  [APB_DATA_WIDTH-1:0]  other_rdata_out,
    output  reg  other_ready_out,
    input   other_sel_in,

    `ifdef  APB_WSTRB
        input   [(APB_DATA_WIDTH / 8) -1:0]  other_strb_in,
    `endif

    input   [APB_DATA_WIDTH-1:0]  other_wdata_in,
    input   other_write_in

);


localparam  WAIT_COUNTER_WIDTH  =  $clog2(TIMEOUT_CYCLE);

/*FSM state definition*/
localparam  STATE_RST           =  0;
localparam  STATE_SETUP         =  1;
localparam  STATE_ENABLE        =  2;
localparam  STATE_WAIT          =  3;
localparam  STATE_TRANS         =  4;
localparam  STATE_ERROR         =  5;


reg [TIMEOUT_CYCLE -1: 0]  wait_counter;

reg [5:0]  apb_state;
reg [5:0]  next_state;


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

    next_state   =  0;
    if (!apb_rstn_in)
        next_state[STATE_RST]  =  1'd1;
    else begin
        case (1'd1)

            apb_state[STATE_RST]:begin
                if (!other_sel_in)
                    next_state[STATE_RST]     =   1'd1;
                else if ( other_error_in )
                    next_state[STATE_ERROR]   =   1'd1;
                else
                    next_state[STATE_SETUP]   =   1'd1;
            end

            apb_state[STATE_SETUP]:begin
                if (!other_sel_in || signal_changed || other_error_in)
                    next_state[STATE_ERROR]   =   1'd1;
                else
                    next_state[STATE_ENABLE]  =   1'd1;
            end

            apb_state[STATE_ENABLE] || apb_state[STATE_WAIT]: begin
                if (!other_sel_in || signal_changed || other_error_in || wait_timeout)
                    next_state[STATE_ERROR]   =   1'd1;
                else if (apb_ready_in)
                    next_state[STATE_TRANS]   =   1'd1;
                else
                    next_state[STATE_WAIT]    =   1'd1;
            end
            
            default: 
                next_state[STATE_RST]  =  1'd1;

        endcase

    end

end



///////////////////////////////////Sequential logic/////////////////////////////////////////////
/*-----set apb_state-------*/
always @(negedge apb_clk_in ) begin
    apb_state <= next_state;
end


/*APB tranfers data*/
always @(posedge apb_clk_in or negedge apb_rstn_in ) begin

    if (!apb_rstn_in) begin

        `ifdef  APB_WSTARB
            apb_strb_out      <=  0;
        `endif

        `ifdef  APB_PROT
            apb_prot_out      <=  0;
        `endif

        `ifdef  APB_SLVERR
            apb_slverr_out    <=  0;
        `endif

        apb_addr_out      <=  0;
        apb_penable_out   <=  1;
        apb_psel_out      <=  0;
        apb_wdata_out     <=  0;
        apb_write_out     <=  0;

        other_error_out   <=   0;
        other_rdata_out   <=   0;
        other_ready_out   <=   0;

        wait_counter      <=   0;

    end
    else  begin
            case (1'd1)
                apb_state[STATE_RST]: begin
                    `ifdef  APB_WSTARB
                        apb_strb_out      <=  0;
                    `endif

                    `ifdef  APB_PROT
                        apb_prot_out      <=  0;
                    `endif

                    `ifdef  APB_SLVERR
                        apb_slverr_out    <=  0;
                    `endif

                    apb_addr_out      <=  0;
                    apb_penable_out   <=  1;
                    apb_psel_out      <=  0;
                    apb_wdata_out     <=  0;
                    apb_write_out     <=  0;

                    other_error_out   <=   0;
                    other_rdata_out   <=   0;
                    other_ready_out   <=   0;

                    wait_counter      <=   0;
                    
                end

                apb_state[STATE_SETUP]:begin

                    `ifdef  APB_PROT
                        apb_prot_out       <=  other_prot_in;
                    `endif
                    `ifdef  APB_WSTRB
                        apb_strb_out       <=  other_strb_in;
                    `endif

                    apb_addr_out            <=  other_addr_in;
                    apb_penable_out         <=  0;
                    apb_psel_out            <=  1;
                    apb_write_out           <=  other_write_in;
                    apb_wdata_out           <=  other_write_in? other_wdata_in: 0;
                end

                apb_state[STATE_ENABLE]: apb_penable_out <= 1;

                apb_state[STATE_WAIT]:   wait_counter <= (wait_counter + 1);

                apb_state[STATE_TRANS]:begin
                    apb_psel_out            <=  0;
                    apb_penable_out         <=  1;
                    other_ready_out         <=  1;

                    `ifdef  APB_SLVERR
                        other_error_out  <=  apb_slverr_in;
                        apb_slverr_out   <=  0;
                    `else
                        other_error_out  <=  0;
                    `endif

                    other_rdata_out      <=  apb_write_out? 0: apb_rdata_in;

                end

                apb_state[STATE_ERROR]: begin
                    apb_psel_out        <=  0;
                    apb_penable_out     <=  0;
                    other_error_out     <=  1;
                    other_ready_out     <=  1;
                end
                default: ;
        endcase

    end

end



assign  addr_chagned   =  ( other_addr_in  != apb_addr_out);
assign  write_changed  =  ( other_write_in != other_write_in);
assign  wdata_changed  =  apb_write_out && (other_wdata_in != apb_wdata_out);

`ifdef  APB_PROT
assign  prot_changed   =  ( other_prot_in != apb_prot_out );
`else
assign  prot_changed   =  0;   
`endif

`ifdef  APB_WSTRB
assign  strb_changed   =  ( other_strb_in != apb_strb_out );
`else
assign  strb_changed   =  0;   
`endif


assign  signal_changed = addr_chagned || write_changed || wdata_changed 
                            || prot_changed || strb_changed;


assign  other_clk_out = apb_clk_in;
assign  wait_timeout  =  (wait_counter == TIMEOUT_CYCLE);




endmodule


