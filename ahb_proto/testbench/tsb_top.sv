
/*********************************************************************************************
* File Name:     top.sv
* Author:          wuqlan
* Email:           
* Date Created:    2022/12/28
* Description:      Top module of testbench.
*
*
* Version:         0.1
**************************************************************************************/

`include  "definition.sv"
`include  "ahb_agent.sv"
`include  "ahb_transaction.sv"
`include  "ahb_scoreboard.sv"
`include  "ahb_env.sv"
`include  "default_test.sv"
`include  "uvm_macros.svh"

import uvm_pkg::*;

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
  slave_if  vslave_ifs[0:`APB_SLAVE_DEVICES -1]();
  apb_if  top_apb_bus( .clk(clk), .rstn(rstn));

  apb_master_if #( `APB_DATA_WIDTH, ` APB_ADDR_WIDTH, `APB_SLAVE_DEVICES) apb_bus_master(
            .apb_addr_out(top_apb_bus.addr),
            .apb_clk_in(top_apb_bus.clk),
            .apb_penable_out(top_apb_bus.penable),
            .apb_prot_out(top_apb_bus.prot),
            .apb_pselx_out(top_apb_bus.sels),
            .apb_rdata_in(top_apb_bus.rdata),
            .apb_ready_in(top_apb_bus.master_ready),
            .apb_rstn_in(top_apb_bus.rstn),
            .apb_slverr_in(top_apb_bus.master_error_in),
            .apb_slverr_out(top_apb_bus.master_error_out),
            .apb_strb_out(top_apb_bus.strb),
            .apb_wdata_out(top_apb_bus.wdata),
            .apb_write_out(top_apb_bus.write),

            .other_addr_in(vmaster_if.addr),
            .other_clk_out(vmaster_if.clk),
            .other_error_out(vmaster_if.master_error),
            .other_error_in(vmaster_if.other_error),
            .other_prot_in(vmaster_if.prot),
            .other_ready_out(vmaster_if.ready),
            .other_rdata_out(vmaster_if.rdata),
            .other_sels_in(vmaster_if.sels),
            .other_strb_in(vmaster_if.strb),
            .other_wdata_in(vmaster_if.addr),
            .other_write_in(vmaster_if.write),
            .other_valid_in(vmaster_if.valid)
  );


  genvar iter;
  generate
  for ( iter = 0;  iter < `APB_SLAVE_DEVICES;  iter++) begin
      apb_slave_if #(`APB_DATA_WIDTH, ` APB_ADDR_WIDTH)  apb_bus_slave(
          .apb_addr_in(top_apb_bus.addr),
          .apb_clk_in(top_apb_bus.clk),
          .apb_penable_in(top_apb_bus.penable),
          .apb_prot_in(top_apb_bus.prot),
          .apb_psel_in(top_apb_bus.sels[i]),
          .apb_rdata_out(top_apb_bus.rdata),
          .apb_ready_out(top_apb_bus.slave_ready[i]),
          .apb_rstn_in(top_apb_bus.rstn),
          .apb_strb_in(top_apb_bus.strb), 
          .apb_slverr_out(top_apb_bus.slave_error_out[i]),
          .apb_slverr_in(top_apb_bus.master_error_out),
          .apb_wdata_in(top_apb_bus.wdata),
          .apb_write_in(top_apb_bus.write),


          .other_addr_out(vslave_ifs[i].addr),
          .other_clk_out(vslave_ifs[i].clk),    
          .other_error_in(vslave_ifs[i].other_error),
          .other_error_out(vslave_ifs[i].slave_error),    
          .other_ready_in(vslave_ifs[i].ready),
          .other_ready_out(vslave_ifs[i].slave_ready),
          .other_rdata_in(vslave_ifs[i].rdata),
          .other_sel_out(vslave_ifs[i].sel),
          .other_strb_out(vslave_ifs[i].strb),
          .other_wdata_out(vslave_ifs[i].wdata),
          .other_write_out(vslave_ifs[i].write),
          .other_prot_out(vslave_ifs[i].prot)
      );
  end
  endgenerate

  initial begin
      $vcdpluson();
      $vcdplusmemon;
  end

  initial begin
    run_test("default_test");
  end



  initial begin
    uvm_config_db #(VTSB_MASTER_T)::set(null, "uvm_test_top.env.master_agt.drv",  "vif_master", vmaster_if);
    uvm_config_db #(VTSB_MASTER_T)::set(null, "uvm_test_top.env.master_agt.mon",  "vif",  input_if);

    for (int i = 0; i < `AHB_SLAVE_DEVICES;  i++) begin
      uvm_config_db #(VTSB_SLAVE_T)::set(null, "uvm_test_top.env.slave_agt" `"i`"".mon",  "vif",  input_if);
    end

  end



endmodule


