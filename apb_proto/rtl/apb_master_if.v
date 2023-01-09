
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



module  apb_master_if(

    apb_addr_out,
    apb_clk_in,
    apb_penable_out,
    apb_prot_out,
    apb_pselx_out,
    apb_rdata_in,
    apb_ready_in,
    apb_rstn_in,
    apb_slverr_in,
    apb_slverr_out,
    apb_strb_out,
    apb_wdata_out,
    apb_write_out,

    other_addr_in,
    other_clk_out,
    other_error_out,
    other_error_in,
    other_prot_in,
    other_ready_out,
    other_rdata_out,
    other_sels_in,
    other_strb_in,
    other_wdata_in,
    other_write_in,
    other_valid_in

);

/*APB the width of addr and data*/
parameter   APB_DATA_WIDTH = 32;
parameter   APB_ADDR_WIDTH = 32;
parameter SLAVE_DEVICES = 4;


/*other sel width*/
localparam  OTHER_SEL_WIDTH = $clog2(SLAVE_DEVICES);
localparam  OTHER_STRB_WIDTH = (APB_DATA_WIDTH / 8);


/*FSM state definition*/
localparam  STATE_RST  =  3'd0;
localparam  STATE_SETUP  =  3'd1;
localparam  STATE_ENTRY_WAIT  =  3'd2;
localparam  STATE_WAIT  =   3'd3;
localparam  STATE_TRANS  =   3'd4;
localparam  STATE_ERROR  =  3'd5;


input  [APB_DATA_WIDTH-1:0] apb_rdata_in;
input  apb_clk_in;
input  apb_rstn_in;
input  apb_ready_in;
input  apb_slverr_in;
input  [APB_ADDR_WIDTH-1:0]  other_addr_in;
input  [APB_DATA_WIDTH-1:0] other_wdata_in;
input  other_write_in;
input  other_error_in;
input [2:0] other_prot_in;
input  [OTHER_SEL_WIDTH:0] other_sels_in;
input  [OTHER_STRB_WIDTH -1:0] other_strb_in; 
input  other_valid_in; 


output  [APB_ADDR_WIDTH-1:0]  apb_addr_out;
output  [APB_DATA_WIDTH-1:0]  apb_wdata_out;
output  apb_write_out;
output  apb_penable_out;
output [SLAVE_DEVICES-1:0] apb_pselx_out;
output [2:0] apb_prot_out;
output  apb_slverr_out;
output [OTHER_STRB_WIDTH -1: 0] apb_strb_out; 
output  other_error_out;
output  other_ready_out;
output  other_clk_out;
output  [APB_DATA_WIDTH-1:0] other_rdata_out;



reg [APB_ADDR_WIDTH-1:0] apb_addr_out;
reg [APB_DATA_WIDTH-1:0] apb_wdata_out;
reg [APB_DATA_WIDTH-1:0] apb_rdata;
reg [SLAVE_DEVICES -1 :0] apb_pselx_out;
reg [OTHER_STRB_WIDTH -1:0] apb_strb_out;
reg [2:0] apb_prot_out;
reg apb_penable_out;
reg apb_write_out;
reg apb_slverr_out;
reg other_error_out;
reg other_ready_out;
reg [SLAVE_DEVICES -1:0] other_sels;


reg [2:0]  apb_state;
reg [2:0]  next_state;

//////////////////////////////////Combinatorial logic//////////////////////////////////////////

/*Get the apb_psel signal based on the other_sels_in*/
always @(other_sels_in) begin
    other_sels = 0;
    if (other_sels_in)
        other_sels[other_sels_in - 1] = 1'b1;

end



/*FSM state*/
always @(*) begin

    if (!apb_rstn_in)
        next_state = STATE_RST;
    else begin
        case (apb_state)

        STATE_RST:begin
            if (other_valid_in && (!other_sels || other_error_in) )
                next_state = STATE_ERROR;
            else if (other_valid_in)
                next_state = STATE_SETUP;
            else
                next_state = STATE_RST;
        end

        STATE_SETUP:begin
            if ( !other_valid_in || (other_sels != apb_pselx_out)  || other_error_in)
                next_state = STATE_ERROR;
            else if (apb_ready_in) 
                next_state = STATE_TRANS;
            else
                next_state = STATE_ENTRY_WAIT;
            
        end

        STATE_ENTRY_WAIT:begin
            if ( !other_valid_in || (other_sels != apb_pselx_out)  || other_error_in)
                next_state = STATE_ERROR;
            else if (apb_ready_in) 
                next_state = STATE_TRANS;
            else
                next_state = STATE_WAIT;
        end

    
        STATE_WAIT:begin
            if ( !other_valid_in || (other_sels != apb_pselx_out))
                next_state = STATE_ERROR;
            else if (apb_ready_in) 
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


/*Set apb_state*/
always @(negedge apb_clk_in  or  negedge apb_rstn_in ) begin

    if (!apb_rstn_in) 
        apb_state <= STATE_RST;
    else
        apb_state <= next_state;
end


/*APB tranfers data*/
always @(posedge apb_clk_in) begin

    casex (apb_state)
        STATE_RST: begin
            apb_addr_out <= 0;
            apb_rdata <=0;
            apb_wdata_out <= 0;
            apb_strb_out <= 0;
            apb_prot_out <= 0;
            apb_penable_out <= 1;
            apb_pselx_out <= 0;            
            apb_write_out <= 0;
            apb_slverr_out <= 0;

            other_error_out <= 0;
            other_ready_out <= 0;
            
        end

        STATE_SETUP:begin
            apb_addr_out <= other_addr_in;
            apb_penable_out <= 0;
            apb_prot_out <= other_prot_in;
            apb_strb_out <= other_strb_in;
            apb_write_out <= other_write_in;
            apb_pselx_out <= other_sels;
            if (other_write_in)
                apb_wdata_out <= other_wdata_in;
        end

        STATE_ENTRY_WAIT: apb_penable_out <= 1;

        STATE_WAIT:;

        STATE_TRANS:begin
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

        STATE_ERROR: begin
        apb_pselx_out   <= 0;
        apb_penable_out <= 0;
        other_error_out <= 1;
        other_ready_out <= 1;
        end

        default: ;
    endcase

end



assign  other_clk_out = apb_clk_in;
assign  other_rdata_out = apb_rdata;


endmodule


