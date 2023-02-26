
/**********************************************************************************************************************************
* Module Name:     apb_master_if
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB master interface.
*                  Address and data bus widths are configurable using APB_ADDR_WIDTH and APB_DATA_WIDTH parameters
*                  apb_psel width can also be configured using SLAVE_DEVICES.
* Version:         0.1
*********************************************************************************************************************************/


module  apb_master_if  #(   parameter   APB_DATA_WIDTH  =  32,
                            parameter   APB_ADDR_WIDTH  =  32,
                            parameter   TIMEOUT_CYCLE   =  6,
                            localparam  OTHER_STRB_WIDTH = (APB_DATA_WIDTH / 8)
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
        output  reg  [OTHER_STRB_WIDTH -1: 0]  apb_strb_out,
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
        input   [OTHER_STRB_WIDTH -1:0]  other_strb_in,
    `endif

    input   other_valid_in,
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


wire   addr_valid;
wire   addr_changed;





//////////////////////////////////Combinatorial logic//////////////////////////////////////////


/*FSM state*/
always @(*) begin

    next_state   =  0;
    if (!apb_rstn_in)
        next_state[STATE_RST]  =  1'd1;
    else begin
        case (1'd1)

            next_state[STATE_RST]:begin
                
            end

            next_state[STATE_SETUP]:begin

                
            end

            next_state[STATE_ENABLE]:begin

            end

        
            next_state[STATE_WAIT]:begin

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
                    apb_addr_out <= other_addr_in;
                    apb_penable_out <= 0;
                    apb_prot_out <= other_prot_in;
                    apb_strb_out <= other_strb_in;
                    apb_write_out <= other_write_in;
                    apb_pselx_out <= other_sels;
                    if (other_write_in)
                        apb_wdata_out <= other_wdata_in;
                end

                apb_state[STATE_ENABLE]: apb_penable_out <= 1;

                apb_state[STATE_WAIT]:;

                apb_state[STATE_TRANS]:begin
                    apb_penable_out <= 1;
                    other_ready_out <= 1;

                    if (apb_slverr_in || other_error_in) begin
                        other_error_out <= 1;
                        apb_slverr_out <= 1;
                    end
                    else begin
                        if (!apb_write_out)
                            apb_rdata <= apb_rdata_in;
                    end

                end

                apb_state[STATE_ERROR]: begin
                    apb_pselx_out   <= 0;
                    apb_penable_out <= 0;
                    other_error_out <= 1;
                    other_ready_out <= 1;
                end
                default: ;
        endcase

    end

end



assign  other_clk_out = apb_clk_in;
assign  other_rdata_out = apb_rdata;







endmodule

