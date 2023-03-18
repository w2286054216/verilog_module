
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


    master_if  vmaster_if ();
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


            /*------slave device output-----*/
            .slave1_rdata_in(vslave_ifs[0].rdata),    
            .slave1_readyout_in(vslave_ifs[0].ready),
            .slave1_resp_in(vslave_ifs[0].resp),
            .slave2_rdata_in(vslave_ifs[1].rdata),    
            .slave2_readyout_in(vslave_ifs[1].ready),
            .slave2_resp_in(vslave_ifs[1].resp)
    );

    ahb_decoder #(  `SLAVES_BASE_ADDR,    `AHB_SPACE_WIDTH,   
                        `AHB_ADDR_WIDTH,      `AHB_SLAVE_DEVICES )
                decoders (

                .ahb_clk_in(decoder.clk),
                .ahb_rstn_in(decoder.rstn),

                .ahb_addr_in(vmaster_if.addr),
                .multi_ready_in(multip.master_ready),
                .multi_sel_out(multip.decoder_sel),
                .slave_sel_out(decoder.selx)
    
            );


    ahb_master_if #( `AHB_DATA_WIDTH, ` AHB_ADDR_WIDTH, `AHB_SLAVE_DEVICES)
                    ahb_bus_master(
                            .ahb_addr_out(top_ahb_bus.addr),
                            .ahb_clk_in(top_ahb_bus.clk),
                            .ahb_penable_out(top_ahb_bus.penable),
                            .ahb_pselx_out(top_ahb_bus.sels),
                            .ahb_rdata_in(top_ahb_bus.rdata),
                            .ahb_ready_in(top_ahb_bus.master_ready),
                            .ahb_rstn_in(top_ahb_bus.rstn),
                            .ahb_slverr_in(top_ahb_bus.master_error_in),
                            .ahb_slverr_out(top_ahb_bus.master_error_out),
                            .ahb_wdata_out(top_ahb_bus.wdata),
                            .ahb_write_out(top_ahb_bus.write),

                            `ifdef  AHB_PROT
                                .ahb_prot_out(top_ahb_bus.prot),
                                .other_prot_in(vmaster_if.prot),
                            `endif
                            `ifdef  AHB_WSTRB
                                .ahb_strb_out(top_ahb_bus.strb),
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
                            .other_valid_in(vmaster_if.valid)
                    );


    genvar iter;
    generate
    for ( iter = 0;  iter < `AHB_SLAVE_DEVICES;  iter++) begin
        ahb_slave_if #(`AHB_DATA_WIDTH, `AHB_ADDR_WIDTH)  ahb_bus_slave(
                .ahb_addr_in(top_ahb_bus.addr),
                .ahb_clk_in(top_ahb_bus.clk),
                .ahb_penable_in(top_ahb_bus.penable),
                
                .ahb_psel_in(decoder.selx[i]),
                .ahb_rdata_out(multip.slaves_rdata[i]),
                .ahb_ready_out(multip.slaves_ready[i]),
                .ahb_resp_out(multip.slaves_resp[i]),
                .ahb_rstn_in(top_ahb_bus.rstn),


                .ahb_wdata_in(top_ahb_bus.wdata),
                .ahb_write_in(top_ahb_bus.write),


                `ifdef  AHB_PROT
                    .ahb_prot_in(top_ahb_bus.prot),
                    .other_prot_out(vslave_ifs[i].prot),
                `endif
                `ifdef  AHB_WSTRB
                    .ahb_strb_in(top_ahb_bus.strb),
                    .other_strb_out(vslave_ifs[i].strb),
                `endif


                .other_addr_out(vslave_ifs[i].addr),
                .other_clk_out(vslave_ifs[i].clk),    
                .other_error_in(vslave_ifs[i].other_error),
                .other_error_out(vslave_ifs[i].slave_error),    
                .other_ready_in(vslave_ifs[i].ready),
                .other_ready_out(vslave_ifs[i].slave_ready),
                .other_rdata_in(vslave_ifs[i].rdata),
                .other_sel_out(vslave_ifs[i].sel),
                .other_wdata_out(vslave_ifs[i].wdata),
                .other_write_out(vslave_ifs[i].write)
            
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
        uvm_config_db #(VTSB_MASTER_T)::set(null, "uvm_test_top.env.m_agt.drv",  "vif",    vmaster_if);
        uvm_config_db #(VTSB_MASTER_T)::set(null, "uvm_test_top.env.m_agt.mon",  "m_vif",  vmaster_if);

        for (int i = 0; i < `AHB_SLAVE_DEVICES;  i++) begin
            string str;
            $sformat(str , "uvm_test_top.env.s_agts%d.mon",  i);
            uvm_config_db #(VTSB_SLAVE_T)::set(null, str,  "s_vif",  vslave_ifs[i]);
        end
    end


endmodule


