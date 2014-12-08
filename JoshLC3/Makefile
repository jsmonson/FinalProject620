TOPLEVEL=lc3
VERILOG_FILES=lc3Pkg.sv lc3_control.sv lc3_datapath.sv lc3.sv 

questa_gui: 
	vlib work
	vmap work work
	vlog -mfcu -sv ${VERILOG_FILES}
	vsim -novopt -coverage -msgmode both -displaymsgmode both -do "view wave;do wave.do;run -all" ${TOPLEVEL}

questa_batch: ${VERILOG_FILES} clean
	vlib work
	vmap work work
	vlog -mfcu -sv ${VERILOG_FILES}
	vsim -c -novopt -coverage -do "run -all" ${TOPLEVEL}

clean:
	@rm -rf work transcript vsim.wlf
