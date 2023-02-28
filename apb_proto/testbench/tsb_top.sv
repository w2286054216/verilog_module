
/*********************************************************************************
* File Name:     top.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Top module of testbench.
*
*
* Version:         0.1
**********************************************************************************/



`include "definition.sv"
`include "environment.sv"

`include  "definition.sv"
`include  "master_if.sv"
`include  "slave_if.sv"
`include  "apb_case0.sv"

`include  "uvm_pkg.sv"

import  uvm_pkg::*;


module top;

  logic rstn, clk;
  
  // System Clock and Reset
  initial begin
    rstn = 1; clk = 1;
    #5 rstn = 0;
    #5 clk = 0;
    #5 rstn = 1; clk = 1;
    forever #5 clk = ~clk;
  end


    master_if  vmaster_if ();
    slave_if  vslave_if();
    apb_if  top_apb_bus( .clk(clk), .rstn(rstn));

    apb_master_if #( `APB_DATA_WIDTH, ` APB_ADDR_WIDTH, `APB_SLAVE_DEVICES) apb_bus_master(
             .apb_addr_out(top_apb_bus.addr),
             .apb_clk_in(top_apb_bus.clk),
             .apb_penable_out(top_apb_bus.penable),
             .apb_pselx_out(top_apb_bus.sels),
             .apb_rdata_in(top_apb_bus.rdata),
             .apb_ready_in(top_apb_bus.master_ready),
             .apb_rstn_in(top_apb_bus.rstn),
             .apb_wdata_out(top_apb_bus.wdata),
             .apb_write_out(top_apb_bus.write),

            `ifdef  APB_PROT
                .apb_prot_out(top_apb_bus.prot),
                .other_prot_in(vmaster_if.prot),             
            `endif
            `ifdef  APB_SLVERR
                .apb_slverr_in(top_apb_bus.master_error_in),
                .apb_slverr_out(top_apb_bus.master_error_out),
            `endif
            `ifdef  APB_WSTRB
                .apb_strb_out(top_apb_bus.strb),
                .other_strb_in(vmaster_if.strb),             
            `endif

             .other_addr_in(vmaster_if.addr),
             .other_clk_out(vmaster_if.clk),
             .other_error_out(vmaster_if.master_error),
             .other_error_in(vmaster_if.other_error),
             .other_ready_out(vmaster_if.ready),
             .other_rdata_out(vmaster_if.rdata),
             .other_sels_in(vmaster_if.sels),
             .other_wdata_in(vmaster_if.addr),
             .other_write_in(vmaster_if.write),
    );


    apb_slave_if #(`APB_DATA_WIDTH, ` APB_ADDR_WIDTH)  apb_bus_slave(
            .apb_addr_in(top_apb_bus.addr),
            .apb_clk_in(top_apb_bus.clk),
            .apb_penable_in(top_apb_bus.penable),
            .apb_psel_in(top_apb_bus.sel),
            .apb_rdata_out(top_apb_bus.rdata),
            .apb_ready_out(top_apb_bus.slave_ready),
            .apb_rstn_in(top_apb_bus.rstn),
            .apb_wdata_in(top_apb_bus.wdata),
            .apb_write_in(top_apb_bus.write),

            `ifdef  APB_SLVERR
                .apb_slverr_out(top_apb_bus.slave_error_out),
                .apb_slverr_in(top_apb_bus.master_error_out),
            `endif
            `ifdef  APB_PROT
                .apb_prot_in(top_apb_bus.prot),
                .other_prot_out(vslave_if.prot),
            `endif
            `ifdef  APB_WSTRB
                .apb_strb_in(top_apb_bus.strb), 
                .other_strb_out(vslave_if.strb),
            `endif

            .other_addr_out(vslave_if.addr),
            .other_clk_out(vslave_if.clk),
            .other_error_in(vslave_if.other_error),
            .other_error_out(vslave_if.slave_error),    
            .other_ready_in(vslave_if.ready),
            .other_ready_out(vslave_if.slave_ready),
            .other_rdata_in(vslave_if.rdata),
            .other_sel_out(vslave_if.sel),
            .other_wdata_out(vslave_if.wdata),
            .other_write_out(vslave_if.write)

      );
        

    initial begin
      run_test("apb_case0");
    end

    initial begin
        uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.m_agt.drv", "vif", vmaster_if);
        uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.m_agt.mon", "m_vif", vmaster_if);
        uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.s_agt.mon", "s_vif", vslave_if);
    end


    initial begin
        $vcdpluson();
        $vcdplusmemon;
    end

endmodule



