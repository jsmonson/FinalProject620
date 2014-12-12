virtual class Driver_cbs;
    virtual task pre_tx(ref MemoryTransaction t);
    endtask 
    virtual task post_tx(ref MemoryTransaction t);
    endtask 
  endclass 
  
class Driver;
      mailbox #(MemoryTransaction) agt2drv;
      MemoryTransaction tr;
	  Driver_cbs cbs[$];
	  int mem_tran_num;
	  vLC3if lc3if;
      function new(input mailbox #(MemoryTransaction) agt2drv, input int mem_tran_num, vLC3if lc3if);
        this.agt2drv = agt2drv;
		this.mem_tran_num = mem_tran_num;
		this.lc3if = lc3if;
	  endfunction
      task run(input int count);
		repeat(count) begin
			agt2drv.get(tr);
			foreach(cbs[i]) cbs[i].pre_tx(tr); // callbacks
				transmit(tr);
			foreach (cbs[i]) cbs[i].post_tx(tr);
		end
    endtask
	/*task init_reset(input int count);
		lc3if.rst <= 1'b1;
		repeat(count) @lc3if.cb;
		lc3if.rst <= 1'b0;
	endtask*/
	task transmit(MemoryTransaction tr);
		#1;
		$display("[%0t] Drv: Sending Transaction...",$time);
		if (tr.rst) begin
			$display("[%0t] Reset!",$time);
			lc3if.rst <= 1'b1;
			repeat(tr.reset_cycles) @lc3if.cb;
		end
		else begin
			lc3if.cb.IRQ <= tr.IRQ;
			lc3if.cb.INTV <=tr.INTV;
			lc3if.cb.INTP <= tr.INTP;
			while (!$root.top.LC3.ldMAR) begin
				@lc3if.cb;
			end
			repeat(mem_tran_num) @lc3if.cb;
			lc3if.cb.memory_dout <= tr.DataOut;
			lc3if.cb.MemoryMappedIO_in <= tr.MemoryMappedIO_in;
			lc3if.cb.MCR <= tr.MCR;
			lc3if.cb.memRDY <= 1;
			@lc3if.cb;
			lc3if.cb.memRDY <= 0;
		end
	endtask
  endclass
 
 