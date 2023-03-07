#/**************************************************/
#/* dc_shell-t -f compile_apb.tcl                   */
#/*                                                 */
#/* OSU FreePDK 45nm                                */
#/**************************************************/

#设计文件
set my_verilog_files [ list apb_master_if.v  apb_slave_if.v ]

#顶层模块
set my_toplevel apb_master_if

#时钟
set my_clk_freq_MHz 100

#寄存器输入时延
set my_input_delay_ns 0.1

#寄存器输出时延
set my_output_delay_ns 0.1


#/**************************************************/
#/*             设置io引脚                         */
#/**************************************************/
set  clks  [get_ports clk]
set  rstns [get_ports rstn]
set my_inputs   [get_ports in]
set my_outputs  [get_ports out]



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
   set clk_name $my_clock_pin
   create_clock -period $my_period $clk_name
} else {
   set clk_name vclk
   create_clock -period $my_period -name $clk_name
}

#时钟网络
set dont_touch_ network $clks
set_drive  0 $clks        ;#时钟端口驱动为无限大
set_ideal_network  $clks     ;#时钟网络为理想网络

#复位网络
set dont_touch_ network $rstns
set_drive  0 $rstns    ;#复位端口驱动为无限大
set_ideal_network  $rstns      ;#复位网络为理想网络

#时延
set_input_delay $my_input_delay_ns -clock $clk_name [remove_from_collection [all_inputs] $clks]
set_output_delay $my_output_delay_ns -clock $clk_name [all_outputs]

#/**************************************************/
#/*                面积约束                       */
#/**************************************************/
set_max_fanout   4    $my_inputs
set_max_area     0     ;#面积尽可能小



#/**************************************************/
#/*                设计综合                       */
#/**************************************************/
analyze -f verilog $my_verilog_files
current_design $my_toplevel
elaborate $my_toplevel

link
uniquify





set_driving_cell  -lib_cell INVX1  [all_inputs]


compile -ungroup_all -map_effort medium

compile -incremental_mapping -map_effort medium

check_design
report_constraint -all_violators

#保存综合后的网表
set out_dir  [format "%s%s"  pwd "/result"].
set filename [format "%s%s%s"  $out_dir $my_toplevel ".vh"]
write_file -f verilog -hier -output $filename

#保存反标文件
set filename [format "%s%s%s" $out_dir $my_toplevel ".sdf"]
write_sdf $filename

#保存整个工程文件
set filename [format "%s%s%s" $out_dir $my_toplevel ".ddc"]
write_file -f ddc -hier -output  $filename

#产生报告
redirect timing.rep { report_timing }
redirect cell.rep { report_cell }
redirect power.rep { report_power }
redirect constraint.rep { report_constraint }


quit
