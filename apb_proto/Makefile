
DIR = $(shell pwd)
RTL_DIR = ${DIR}/rtl/
TSB_DIR = ${DIR}/testbench/


VOPTS = -sverilog +v2k -debug_acc+all  +libext+.v -y ${RTL_DIR}  +libext+.sv -y  ${TSB_DIR} +incdir+${TSB_DIR} +race=all -race -raced
SOPT = +ntb_solver_mode=1 -l simv.log




simv.vdb:	simv
	./simv ${SOPT} +ntb_random_seed=19  +UVM_PHASE_TRACE
	./simv ${SOPT} +ntb_random_seed_automatic  +UVM_PHASE_TRACE

simv:
	find ${RTL_DIR} -name "*.v" > rtl_filelist.f
	find ${TSB_DIR}  -name "*.sv" > tsb_filelist.f
	vcs ${VOPTS} -l comp.log  -f tsb_filelist.f   -f rtl_filelist.f



clean:
	@rm -rf ${OUT_DIR}
	@rm -rf *~ *.log *.vpd vc_hdrs.h .vcsmx_rebuild DVEfiles .nfs* .restartSimSession*
	@rm -rf simv* csrc* core* *.vrh *shell.v .__solver* *.key .ucli* .nfs* urgReport race* *.tcl





