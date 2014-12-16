TOPLEVEL=top
VERILOG_FILES= lc3_interface.sv EnvironmentPkg.sv factory_pkg.sv test_program.sv JoshLC3/lc3Pkg.sv JoshLC3/lc3_control.sv JoshLC3/lc3_datapath.sv JoshLC3/lc3.sv  top.sv

Test0: compile
	vsim -novopt -coverage -do "view wave; do wave.do; run -all" +TESTNAME=Test0 ${TOPLEVEL} 

questa_gui: 
	vlib work
	vmap work work
	vlog -mfcu -sv ${VERILOG_FILES}
#	vsim -novopt -coverage -msgmode both -displaymsgmode both -do "view wave;do wave.do;run -all" ${TOPLEVEL}

compile: ${VERILOG_FILES} clean
	vlib work
	vmap work work
	vlog -mfcu -sv ${VERILOG_FILES}
#	vsim -c -novopt -coverage -do "run -all" ${TOPLEVEL}

clean:
	@rm -rf work transcript vsim.wlf
