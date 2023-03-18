
DIR = $(shell pwd)
RTL_DIR = ${DIR}/rtl
TSB_DIR = ${DIR}/testbench


VOPTS = -sverilog +v2k -debug_acc+all +vpi   +incdir+$(UVM_HOME)  -CFLAGS -DVCS $(UVM_HOME)/dpi/uvm_dpi.cc   \
			 ${TSB_DIR}/ahb_pkg.sv $(UVM_HOME)/uvm_pkg.sv +incdir+${TSB_DIR} +race=all -race -raced  +libext+.v 	\
			-y ${RTL_DIR}  +libext+.sv -y  ${TSB_DIR}  -timescale=1ns/1ns
SOPT = +ntb_solver_mode=1 -l simv.log




simv.vdb:	simv
	./simv ${SOPT} +ntb_random_seed=19
	./simv ${SOPT} +ntb_random_seed_automatic

simv:
	find ${RTL_DIR} -name "*.v" > rtl_filelist.f
	echo  ${TSB_DIR}/ahb_pkg.sv  >  tsb_filelist.f
	find ${TSB_DIR}  -name "*.sv" >> tsb_filelist.f
	vcs ${VOPTS} -l comp.log  -f tsb_filelist.f   -f rtl_filelist.f



clean:
	@rm -rf ${OUT_DIR}
	@rm -rf *~ *.log *.vpd vc_hdrs.h .vcsmx_rebuild DVEfiles .nfs* .restartSimSession*
	@rm -rf simv* csrc* core* *.vrh *shell.v .__solver* *.key .ucli* .nfs* urgReport race* *.tcl





