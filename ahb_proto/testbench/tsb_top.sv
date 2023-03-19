
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
`include  "ahb_pkg.sv"
`include  "default_case.sv"
`include  "master_if.sv"
`include  "slave_if.sv"
`include  "ahb_if.sv"
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


    master_if  vmaster_if();
    slave_if  vslave_ifs[`AHB_SLAVE_DEVICES]();
    ahb_if  top_ahb_bus( .clk(clk), .rstn(rstn));
    decoder_if  decoder(.clk(clk), .rstn(rstn));
    multip_if   multip( .clk(clk), .rstn(rstn) );

    ahb_multiplexor #( `AHB_DATA_WIDTH,  `AHB_SLAVE_DEVICES) multiplexor(
            .ahb_clk_in(multip.clk),
            .ahb_rstn_in(multip.rstn),

            .ahb_rdata_out(multip.master_rdata),
            .ahb_ready_out(multip.master_ready),
            .ahb_resp_out(multip.master_resp),    

            .decoder_sel_in(multip.decoder_sel),

            .slave1_rdata_in(top_ahb_bus.s_rdata[0]),    
            .slave1_readyout_in(top_ahb_bus.s_ready[0]),
            .slave1_resp_in(top_ahb_bus.s_resp[0]),
            .slave2_rdata_in(top_ahb_bus.s_rdata[1]),    
            .slave2_readyout_in(top_ahb_bus.s_ready[1]),
            .slave2_resp_in(top_ahb_bus.s_resp[1])
    );

    ahb_decoder #(  `SLAVES_BASE_ADDR,    `AHB_SPACE_WIDTH,   
                        `AHB_ADDR_WIDTH,      `AHB_SLAVE_DEVICES )
                decoders (

                .ahb_clk_in(decoder.clk),
                .ahb_rstn_in(decoder.rstn),

                .ahb_addr_in(top_ahb_bus.addr),
                .multi_ready_in(multip.master_ready),
                .multi_sel_out(multip.decoder_sel),
                .slave_sel_out(decoder.selx)
    
            );


    ahb_master_if #( `AHB_DATA_WIDTH, ` AHB_ADDR_WIDTH, `AHB_SLAVE_DEVICES)
                    ahb_bus_master(

                            .ahb_clk_in(top_ahb_bus.clk),
                            .ahb_rstn_in(top_ahb_bus.rstn),

                            .ahb_addr_out(top_ahb_bus.addr),
                            .ahb_burst_out(top_ahb_bus.burst),
                            .ahb_rdata_in(top_ahb_bus.m_rdata),
                            .ahb_ready_in(top_ahb_bus.m_ready),
                            .ahb_resp_in(top_ahb_bus.m_resp),
                            .ahb_size_out(top_ahb_bus.size),


                            `ifdef  AHB_PROT
                                .ahb_prot_out(top_ahb_bus.prot),
                                .other_prot_in(vmaster_if.prot),
                            `endif
                            `ifdef  AHB_WSTRB
                                .ahb_strb_out(top_ahb_bus.strb),
                                .other_strb_in(vmaster_if.strb),
                            `endif


                            .ahb_trans_out(top_ahb_bus.trans),
                            .ahb_wdata_out(top_ahb_bus.wdata),
                            .ahb_write_out(top_ahb_bus.write),


                            .other_addr_in(vmaster_if.addr),
                            .other_burst_in(vmaster_if.burst),
                            .other_busy_out(vmaster_if.busy),
                            .other_clk_out(vmaster_if.clk),
                            .other_delay_in(vmaster_if.delay),
                            .other_error_out(vmaster_if.master_error),
                            .other_error_in(vmaster_if.other_error),
                            .other_ready_out(vmaster_if.ready),
                            .other_rdata_out(vmaster_if.rdata),
                            .other_sel_in(vmaster_if.sel),
                            .other_valid_in(vmaster_if.valid),
                            .other_wdata_in(vmaster_if.addr),
                            .other_write_in(vmaster_if.write)

                    );


    genvar iter;
    generate
    for ( iter = 0;  iter < `AHB_SLAVE_DEVICES;  iter++) begin: gen_slaves
        ahb_slave_if #(`AHB_DATA_WIDTH, `AHB_ADDR_WIDTH)  ahb_bus_slave(

                .ahb_clk_in(top_ahb_bus.clk),
                .ahb_rstn_in(top_ahb_bus.rstn),

                .ahb_addr_in(top_ahb_bus.addr),
                .ahb_burst_in(top_ahb_bus.burst),
                .ahb_rdata_out(top_ahb_bus.s_rdata[iter]),
                .ahb_ready_out(top_ahb_bus.s_ready[iter]),
                .ahb_resp_out(top_ahb_bus.s_resp[iter]),
                .ahb_sel_in(decoder.selx[iter]),                
                .ahb_size_in(top_ahb_bus.size),

                `ifdef  AHB_PROT
                    .ahb_prot_in(top_ahb_bus.prot),
                    .other_prot_out(vslave_ifs[iter].prot),
                `endif
                `ifdef  AHB_WSTRB
                    .ahb_strb_in(top_ahb_bus.strb),
                    .other_strb_out(vslave_ifs[iter].strb),
                `endif

                .ahb_trans_in(top_ahb_bus.trans),

                .ahb_wdata_in(top_ahb_bus.wdata),
                .ahb_write_in(top_ahb_bus.write),


                .other_addr_out(vslave_ifs[iter].addr),
                .other_clk_out(vslave_ifs[iter].clk),    
                .other_error_in(vslave_ifs[iter].other_error),
                .other_error_out(vslave_ifs[iter].slave_error),
                .other_rdata_in(vslave_ifs[iter].rdata),                    
                .other_ready_in(vslave_ifs[iter].ready),
                .other_sel_out(vslave_ifs[iter].sel),
                .other_size_out(vslave_ifs[iter].size),
                .other_wdata_out(vslave_ifs[iter].wdata),
                .other_write_out(vslave_ifs[iter].write)
            
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

        uvm_config_db #(VTSB_MASTER_IF)::set(null, "uvm_test_top.env.m_agt.drv",  "vif",    vmaster_if);
        uvm_config_db #(VTSB_MASTER_IF)::set(null, "uvm_test_top.env.m_agt.mon",  "m_vif",  vmaster_if);


        uvm_config_db #(VTSB_SLAVE_IF)::set(null, "uvm_test_top.env.s_agts0.mon",  "s_vif",  vslave_ifs[0]);
        uvm_config_db #(VTSB_SLAVE_IF)::set(null, "uvm_test_top.env.s_agts1.mon",  "s_vif",  vslave_ifs[1]);


    end


endmodule


