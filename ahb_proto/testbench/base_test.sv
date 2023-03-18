

`ifndef BASE_TEST_SV
`define BASE_TEST_SV


`include "definition.sv"
`include "ahb_env.sv"
`include "uvm_macros.svh"


import uvm_pkg::*;


class base_test extends uvm_test;

    `uvm_component_utils(base_test)

    ahb_env #(`AHB_SLAVE_DEVICES) env;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction
   

    function  void  build_phase(uvm_phase phase);
        super.build_phase(phase);
        env  =  ahb_env #(`AHB_SLAVE_DEVICES)::type_id::create("env", this); 
    endfunction

    extern virtual function void report_phase(uvm_phase phase);

endclass



function void base_test::report_phase(uvm_phase phase);
   uvm_report_server server;
   int err_num;
   uvm_coreservice_t cs;
   super.report_phase(phase);

   cs = uvm_coreservice_t::get();
   server = cs.get_report_server();
   err_num = server.get_severity_count(UVM_ERROR);

   if (err_num != 0) begin
      $display("TEST CASE FAILED");
   end
   else begin
      $display("TEST CASE PASSED");
   end
endfunction


`endif

