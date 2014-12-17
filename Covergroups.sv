covergroup opcode_coverage with function sample(bit ldIR);
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
	n_flag: coverpoint $root.top.LC3.N iff ($root.top.LC3.IR[15:12] == tbBR) {option.weight = 0;}
	z_flag: coverpoint $root.top.LC3.Z iff ($root.top.LC3.IR[15:12] == tbBR) {option.weight = 0;}
	p_flag: coverpoint $root.top.LC3.P iff ($root.top.LC3.IR[15:12] == tbBR) {option.weight = 0;}
	nzp_br: coverpoint $root.top.LC3.IR[11:9] iff ($root.top.LC3.IR[15:12] == tbBR){option.weight = 0;}
	
	n_br: cross n_flag, nzp_br;
	z_br: cross z_flag, nzp_br;
	p_br: cross p_flag, nzp_br;
	
endgroup

covergroup states_coverage with function sample(bit[5:0] state);
	option.per_instance = 1;
	
	states: coverpoint state { ignore_bins nonexistant = {[$root.top.LC3.CONTROL.num_states:63]}; }
endgroup 

covergroup reset_coverage with function sample(bit rst );
	option.per_instance = 1;
	
	reset: coverpoint rst {ignore_bins zero = {0};}
	opcodes: coverpoint $root.top.LC3.IR[15:12]{option.weight = 0;}
	states: coverpoint $root.top.LC3.CONTROL.state {option.weight = 0;}
	// reset has asserted in every opcode
	reset_in_opcodes: cross reset, opcodes;
	// reset has asserted in every state
	reset_in_all_states: cross reset, states;
endgroup 

covergroup interrupt_coverage with function sample(bit INT);
	option.per_instance = 1;
	opcodes: coverpoint $root.top.LC3.IR[15:12]{option.weight = 0;}
	interrupt: coverpoint INT {option.weight = 0; ignore_bins zero = {0};}
	interrupt_in_all_states: cross interrupt, opcodes;
endgroup

covergroup priority_coverage with function sample(bit[2:0] INTP);
	option.per_instance = 1;
	priority_c: coverpoint INTP {option.weight = 0;}
	interrupt: coverpoint $root.top.lc3_if.IRQ {option.weight = 0; ignore_bins zero = {0};}
	priority_in_all_interrupts : cross priority_c, interrupt;
endgroup

covergroup exception_coverage with function sample(bit ldVector);
	option.per_instance = 1;
	exception_vectors: coverpoint $root.top.LC3.DATAPATH.VectorMUX iff($root.top.LC3.selVectorMUX > 0); // exception vectors
endgroup

covergroup address_coverage with function sample(bit ldMAR);
	option.per_instance = 1;
	address_ranges: coverpoint $root.top.LC3.DATAPATH.MAR{ 
		bins Trap = {[16'h0000:16'h00FF]};
		bins Interrupt = {[16'h0100:16'h01FF]};
		bins User = {[16'h3000:16'hFE00]};
		bins MMAPIO = {[16'hFE00:16'hFFFF]};
	} 
endgroup

class coverClass;
	opcode_coverage o_c;
	states_coverage s_c;
	reset_coverage r_c;
	interrupt_coverage i_c;
	priority_coverage p_c;
	exception_coverage e_c;
	address_coverage a_c;
	function new();
		s_c = new();
		o_c = new();
		r_c = new();
		i_c = new();
		p_c = new();
		e_c = new();
		a_c = new();
	endfunction
	task run();
		fork 
			forever begin
				@$root.top.lc3_if.clk;
				s_c.sample($root.top.LC3.CONTROL.state);
				o_c.sample($root.top.LC3.ldIR);
				i_c.sample($root.top.lc3_if.IRQ);
				p_c.sample($root.top.lc3_if.INTP);
				e_c.sample($root.top.LC3.ldVector);
				a_c.sample($root.top.LC3.ldMAR);
			end
			forever begin
				@$root.top.lc3_if.rst;
				r_c.sample($root.top.lc3_if.rst);
			end
		join
	endtask
endclass
