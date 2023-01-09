
/**********************************************************************************************************************************
* Module Name:     apb_slave_if
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:     APB slave interface.
*                  Address and data bus widths are configurable using APB_ADDR_WIDTH and APB_DATA_WIDTH parameters.
*
* Version:         0.1
*********************************************************************************************************************************/

module  apb_slave_if(

    apb_addr_in,
    apb_clk_in,
    apb_penable_in,
    apb_prot_in,
    apb_psel_in,
    apb_rdata_out,
    apb_ready_out,
    apb_rstn_in,
    apb_strb_in, 
    apb_slverr_out,
    apb_slverr_in,
    apb_wdata_in,
    apb_write_in,


    other_addr_out,
    other_clk_out,    
    other_error_in,
    other_error_out,
    other_ready_in,
    other_ready_out,
    other_rdata_in,
    other_sel_out,
    other_strb_out,
    other_wdata_out,
    other_write_out,
    other_prot_out

);

/*APB the width of addr and data*/
parameter   APB_DATA_WIDTH = 32;
parameter   APB_ADDR_WIDTH = 32;

localparam  OTHER_STRB_WIDTH = (APB_DATA_WIDTH / 8);

/*FSM state definition*/
localparam  STATE_RST  =  3'd0;
localparam  STATE_SETUP  =  3'd1;
localparam  STATE_WAIT  =   3'd2;
localparam  STATE_TRANS  =   3'd3;
localparam  STATE_ERROR  =   3'd4;


input [APB_ADDR_WIDTH -1: 0]  apb_addr_in;
input  apb_clk_in;
input  apb_penable_in;
input  apb_psel_in;
input  apb_rstn_in;
input [APB_DATA_WIDTH-1:0]  apb_wdata_in;
input  apb_write_in;
input [APB_DATA_WIDTH-1:0] other_rdata_in;
input  other_ready_in;
input [2:0] apb_prot_in;
input [OTHER_STRB_WIDTH -1:0] apb_strb_in;
input  apb_slverr_in;
input other_error_in;



output [APB_DATA_WIDTH-1:0] apb_rdata_out;
output apb_ready_out;
output apb_slverr_out;
output [APB_ADDR_WIDTH -1: 0] other_addr_out;
output other_clk_out;
output  other_ready_out;
output [APB_DATA_WIDTH-1:0] other_wdata_out;
output  other_write_out;
output [2:0] other_prot_out;
output [OTHER_STRB_WIDTH -1:0] other_strb_out;
output other_sel_out; 
output other_error_out; 




reg [2:0] apb_state;
reg [2:0] next_state;


reg [APB_ADDR_WIDTH -1: 0] apb_addr;
reg [2:0] apb_prot;
reg [APB_DATA_WIDTH -1: 0] apb_rdata_out;
reg apb_ready_out;
reg apb_sel;
reg apb_slverr_out;
reg [OTHER_STRB_WIDTH-1:0] apb_strb;
reg [APB_DATA_WIDTH -1: 0] apb_wdata;
reg apb_write;
reg other_error_out;
reg other_ready_out;






//////////////////////////////////Combinatorial logic//////////////////////////////////////////


/*FSM state*/
always @(*) begin

    if (!apb_rstn_in)
        next_state = STATE_RST;
    else begin
        case (apb_state)

        STATE_RST:begin
            if ( apb_psel_in && !apb_penable_in )
                next_state = STATE_SETUP;
            else
                next_state = STATE_RST;
        end

        STATE_SETUP:begin

            if ( apb_penable_in ||  !apb_psel_in  || other_error_in)
                next_state = STATE_ERROR;
            else  if (other_ready_in)
                next_state = STATE_TRANS;
            else
                next_state = STATE_WAIT; 
            
        end

        STATE_WAIT:begin

            if ( !apb_penable_in || !apb_psel_in || other_error_in)
                next_state = STATE_ERROR;
            else  if (other_ready_in)
                next_state = STATE_TRANS;
            else
                next_state = STATE_WAIT;  
        end
        
        default: 
            next_state = STATE_RST;

    endcase
        
    end

end





///////////////////////////////////Sequential logic/////////////////////////////////////////////


/*Set apb state*/
always @(negedge apb_clk_in  or negedge apb_rstn_in) begin
    if (!apb_rstn_in)
        apb_state <= STATE_RST;
    else
        apb_state <= next_state;
end


/*Slave transfer data*/
always @(posedge apb_clk_in ) begin
    case (apb_state)
    STATE_RST:begin

        apb_addr <= 0;
        apb_prot <= 0;
        apb_rdata_out <= 0;
        apb_ready_out <= 0;
        apb_slverr_out <= 0;
        apb_sel <= 0;
        apb_strb <= 0;
        apb_wdata <= 0;
        apb_write <= 0;
        other_error_out <= 0;
        
    end

    STATE_SETUP:begin
        apb_addr <= apb_addr_in;
        apb_prot <= apb_prot_in;
        apb_sel <= apb_psel_in;
        apb_strb <= apb_strb_in;
        apb_write <= apb_write_in;
        if (apb_write_in) 
            apb_wdata <= apb_wdata_in;
    end

    STATE_WAIT:begin
        apb_ready_out <= 0;
    end

    STATE_TRANS: begin

        if ( !apb_penable_in || !apb_psel_in) begin
            apb_slverr_out <= 1;
            other_error_out <= 1;   
        end 
        else begin
        other_error_out <= apb_slverr_in;
        apb_slverr_out <= other_error_in;
        if (!apb_write)
            apb_rdata_out <= other_rdata_in;
        end
        apb_ready_out <= 1;
        other_ready_out <= 1;
    end

    STATE_ERROR:begin
        apb_slverr_out <= 1;
        apb_ready_out <= 1;
        
        other_error_out <= 1;
        other_ready_out <= 1;

    end

    default:;
    
    endcase
    
end




assign  other_addr_out  =  apb_addr;
assign  other_clk_out   =  apb_clk_in;
assign  other_prot_out  =  apb_prot;
assign other_sel_out    =  apb_sel;
assign  other_strb_out  =  apb_strb;
assign  other_wdata_out =  apb_wdata;
assign  other_write_out =  apb_write;





endmodule


