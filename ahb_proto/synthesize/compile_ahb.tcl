#/**************************************************/
#/* dc_shell-t -f compile_apb.tcl                   */
#/*                                                 */
#/* OSU FreePDK 45nm                                */
#/**************************************************/

#设计文件
set my_verilog_files [ list ahb_master_if.v  ahb_slave_if.v]

#顶层模块
set my_toplevel ahb_master_if

#时钟
set my_clk_freq_MHz 100

#寄存器输入时延
set my_input_delay_ns 0.1

#寄存器输出时延
set my_output_delay_ns 0.1

set_option  top   $my_toplevel
current_design  $my_toplevel
analyze -f  verilog $my_verilog_files
elaborate  $my_toplevel


#/**************************************************/
#/*             设置io引脚                         */
#/**************************************************/
set  clks  [get_ports  *_clk_* ]
set  rstns [get_ports *_rstn_* ]
set my_inputs   [get_ports *_in]
set my_outputs  [get_ports *_out]



#/**************************************************/
#/*                  工艺库                       */
#/**************************************************/
set OSU_FREEPDK [format "%s%s"  [getenv "PDK_DIR"] "/osu_soc/lib/files"]
set search_path [concat  $search_path $OSU_FREEPDK]
set alib_library_analysis_path $OSU_FREEPDK

set link_library [set target_library [concat  [list gscl45nm.db] [list dw_foundation.sldb]]]
set target_library "gscl45nm.db"
define_design_lib WORK -path  [format "%s%s"  ./work_ $my_toplevel]
set verilogout_show_unconnected_pins "true"
set_ultra_optimization true
set_ultra_optimization -force


#/**************************************************/
#/*                时序约束                       */
#/**************************************************/
set my_period [expr 1000 / $my_clk_freq_MHz]
if {  $clks != [list] } {
   set  clk_name  apb_clk_in
} else {
   set  clk_name  {vclk}
}
create_clock -period $my_period  -name  $clk_name
#时钟网络
set_dont_touch_network $clks
set_drive  0   [get_ports  *_clk_in ]       ;#时钟端口驱动为无限大
set_ideal_network  $clks     ;#时钟网络为理想网络

#复位网络
set_dont_touch_network $rstns
set_drive  0  $rstns    ;#复位端口驱动为无限大
set_ideal_network  $rstns      ;#复位网络为理想网络

#时延
set_input_delay $my_input_delay_ns -clock $clk_name  [remove_from_collection  [all_inputs] [get_ports *_clk_in]]
set_output_delay $my_output_delay_ns -clock $clk_name  [remove_from_collection [all_outputs] [get_ports *_clk_out]]

#/**************************************************/
#/*                面积约束                       */
#/**************************************************/
set_max_fanout   4    $my_inputs
set_max_area     0     ;#面积尽可能小



#/**************************************************/
#/*                设计编译                       */
#/**************************************************/
link
uniquify


set_driving_cell  -lib_cell INVX1  [all_inputs]


compile -ungroup_all -map_effort medium

compile -incremental_mapping -map_effort medium

check_design
report_constraint -all_violators


#保存综合后的网表
set out_dir  [format "%s"   "./result/"].
set filename [format "%s%s%s"  $out_dir $my_toplevel ".vh"]
write_file -f verilog -hier -output $filename

#保存反标文件
set filename [format "%s%s%s" $out_dir $my_toplevel ".sdf"]
write_sdf $filename

#保存整个工程文件
set filename [format "%s%s%s" $out_dir $my_toplevel ".ddc"]
write_file -f ddc -hier -output  $filename

#产生报告
redirect  [format "%s%s%s" "./report/" $my_toplevel "_timing.rep"] { report_timing }
redirect  [format "%s%s%s" "./report/" $my_toplevel "_cell.rep"]   { report_cell }
redirect  [format "%s%s%s" "./report/" $my_toplevel "_power.rep"]  { report_power }
redirect  [format "%s%s%s" "./report/" $my_toplevel "_const.rep"]  { report_constraint }


quit
