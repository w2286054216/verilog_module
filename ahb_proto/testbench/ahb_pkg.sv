/*************************************************************************
* File Name:     monitor.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:        Monitor to get APB transferring data.
*
*
* Version:         0.1
**************************************************************************/

`ifdef  AHB_PKG_SV
`define  AHB_PKG_SV

package  ahb_pkg;


typedef enum bit[2:0] {
    AHB_BURST_SINGLE   =  3'd0,
    AHB_BURST_INCR,
    AHB_BURST_WRAP4,
    AHB_BURST_INCR4,
    AHB_BURST_WRAP8,
    AHB_BURST_INCR8,
    AHB_BURST_WRAP16,
    AHB_BURST_INCR16
} ahb_burst_type;



function  automatic  int  unsigned get_burst_len(ahb_burst_type burst_type);
    
    int  unsigned len;
    
    case (burst_type)
        AHB_BURST_SINGLE:   len = 1;
        AHB_BURST_INCR:     len = 0;
        AHB_BURST_WRAP4:
        AHB_BURST_INCR4:    len = 4;
        AHB_BURST_WRAP8:
        AHB_BURST_INCR8:    len = 8;
        AHB_BURST_WRAP16:
        AHB_BURST_INCR16:   len = 16;
        
    endcase

    return len;
    
endfunction



function  automatic  bit  burst_addr_valid(input int unsigned addr,  input ahb_burst_type burst_type, input bit[2:0]  size);
    
    int unsigned  end_addr;
    int unsigned  burst_len;
    bit  valid;

    burst_len  = get_burst_size(burst_type);

    burst_len  =  burst_len <2 ? 1: burst_len;

    end_addr   =  addr + burst_len * (1 << size);

    valid  =  ( addr & (( 1 << size) - 1)) ||  (addr[12: 10] !=  end_addr[12 : 10] )? 0:  1;

    return valid;
    
endfunction





    
endpackage

`endif

