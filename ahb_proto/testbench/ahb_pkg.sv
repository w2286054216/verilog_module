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



function  int  get_burst_size(ahb_burst_type burst_type);
    
    int size;
    
    case (burst_type)
        AHB_BURST_SINGLE:   size = 1;
        AHB_BURST_INCR:     size = 0;
        AHB_BURST_WRAP4:
        AHB_BURST_INCR4:    size = 4;
        AHB_BURST_WRAP8:
        AHB_BURST_INCR8:    size = 8;
        AHB_BURST_WRAP16:
        AHB_BURST_INCR16:   size = 16;
        
    endcase

    return size;
    
endfunction

    
endpackage

`endif

