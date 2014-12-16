covergroup states with function sample(bit ldIR);
	option.per_instance = 1;
	
	// all states have executed
	opcodes: coverpoint $root.top.LC3.IR[15:12];
	
	// every state has preceded and followed every other states
	preceded_followed: coverpoint opcode_c { 
        bins states[] = (tbBR,tbADD,tbLD,tbST,tbJSR,tbAND,tbLDR,tbSTR,tbRTI,tbNOT,tbLDI,tbSTI,tbJMP,tbRES,tbLEA,tbTRAP => 
						 tbBR,tbADD,tbLD,tbST,tbJSR,tbAND,tbLDR,tbSTR,tbRTI,tbNOT,tbLDI,tbSTI,tbJMP,tbRES,tbLEA,tbTRAP);
    } 
	
	// loads precede/follow stores, and vice versa
	LD_ST: coverpoint opcode_c {
		bins ldst[] = (tbLD,tbLDR,tbLDI,tbLEA => tbST,tbSTR,tbSTI);
		bins loads[] = (tbLD,tbLDR,tbLDI,tbLEA => tbLD,tbLDR,tbLDI,tbLEA);
	}

	// src dst registers have been all registers	
	src1 : coverpoint $root.top.LC3.IR[8:6] iff ($root.top.LC3.IR[15:12] == tbADD || $root.top.LC3.IR[15:12] == tbAND || $root.top.LC3.IR[15:12] == tbNOT);
	src : coverpoint $root.top.LC3.IR[11:9] iff ($root.top.LC3.IR[15:12] == tbST ||$root.top.LC3.IR[15:12] == tbSTI || $root.top.LC3.IR[15:12] == tbSTR );
	src2 : coverpoint $root.top.LC3.IR[2:0] iff ($root.top.LC3.IR[15:12] == tbADD || $root.top.LC3.IR[15:12] == tbAND || $root.top.LC3.IR[15:12] == tbNOT);
	
    baser : coverpoint $root.top.LC3.IR[8:6] iff (($root.top.LC3.IR[15:12] == tbJMP && $root.top.LC3.IR[11]) ||
												  ($root.top.LC3.IR[15:12] == tbJSR && $root.top.LC3.IR[11]) ||  
												   $root.top.LC3.IR[15:12] == tbLDR || $root.top.LC3.IR[15:12] == tbSTR );
												 
	dr : coverpoint $root.top.LC3.IR[11:9] iff ($root.top.LC3.IR[15:12] == tbADD || $root.top.LC3.IR[15:12] == tbAND || 
												$root.top.LC3.IR[15:12] == tbNOT || $root.top.LC3.IR[15:12] == tbLD  || 
												$root.top.LC3.IR[15:12] == tbLDI || $root.top.LC3.IR[15:12] == tbLDR || 
												$root.top.LC3.IR[15:12] == tbLEA );
											
	all_src1 : cross opcode_c,  src1 { // NOT AND ADD
		ignore_bins n_a = binsof(opcode_c) intersect {tbBR,tbLD,tbJSR,tbLDR,tbRTI,tbLDI,tbJMP,tbRES,tbLEA,tbTRAP,tbST,tbSTR,tbSTI}; 
	}
	all_src : cross opcode_c,  src { // ST STI STR
		ignore_bins n_a = binsof(opcode_c) intersect {tbBR,tbADD,tbLD,tbJSR,tbAND,tbLDR,tbRTI,tbNOT,tbLDI,tbJMP,tbRES,tbLEA,tbTRAP};
	}
	all_baser : cross opcode_c,  baser { // JMP JSRR LDR STR
		ignore_bins n_a = binsof(opcode_c) intersect {tbBR,tbADD,tbLD,tbST,tbAND,tbRTI,tbNOT,tbLDI,tbSTI,tbRES,tbLEA,tbTRAP};
	}
	all_dr : cross opcode_c,  baser { // ADD AND NOT LD LDI LDR LEA
		ignore_bins n_a = binsof(opcode_c) intersect {tbBR,tbST,tbJSR,tbSTR,tbRTI,tbSTI,tbJMP,tbRES,tbTRAP};
	}
	
	// all opcodes must have used immediate values
	immediates : coverpoint $root.top.LC3.IR[5] iff ($root.top.LC3.IR[15:12] == tbADD || $root.top.LC3.IR[15:12] == tbAND);
	andadd_imm: cross opcode_c,  immediates {
		ignore_bins n_a = binsof(opcode_c) intersect {tbBR,tbLD,tbST,tbJSR,tbLDR,tbSTR,tbRTI,tbNOT,tbLDI,tbSTI,tbJMP,tbRES,tbLEA,tbTRAP};
	}
	// JSR and JSRR have executed
	jsr_r : coverpoint $root.top.LC3.IR[11] iff ($root.top.LC3.IR[15:12] == tbJSR);
	// RET and JMP have executed
	ret_jmp : coverpoint $root.top.LC3.IR[8:6] iff ($root.top.LC3.IR[15:12] == tbJMP);

	// Branches have been taken for all combinations of NZP flags
	n_flag: coverpoint $root.top.LC3.N iff ($root.top.LC3.IR[15:12] == tbBR);
	z_flag: coverpoint $root.top.LC3.Z iff ($root.top.LC3.IR[15:12] == tbBR);
	p_flag: coverpoint $root.top.LC3.P iff ($root.top.LC3.IR[15:12] == tbBR);
	nzp_br: coverpoint $root.top.LC3.IR[11:9] iff ($root.top.LC3.IR[15:12] == tbBR);
	
	n_br: cross n_flag, nzp_br;
	z_br: cross z_flag, nzp_br;
	p_br: cross p_flag, nzp_br;
	
endgroup

covergroup reset_coverage with function sample(bit rst );
	option.per_instance = 1;
	
	reset: coverpoint $root.top.lc3_if.rst;
	opcodes: coverpoint $root.top.LC3.IR[15:12];
	// reset has asserted in every opcode
	reset_all_states: cross reset, opcode_c;
endgroup 

class coverClass;
	states s_c;
	reset_coverage r_c;
	function new();
		s_c = new();
		r_c = new();
	endfunction
	task run();
		forever begin
			@$root.top.lc3_if.clk;
			s_c.sample($root.top.LC3.ldIR);
			r_c.sample($root.top.lc3_if.rst);
		end
	endtask
endclass
