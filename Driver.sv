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
	task transmit(MemoryTransaction tr);
		#1;
		$display("Drv: Sending Transaction...");
		if (tr.rst) begin
			$display("Reset!");
			lc3if.cb.rst <= 1'b1;
			repeat(tr.reset_cycles) #1;
		end
		else begin
			lc3if.cb.IRQ <= tr.IRQ;
			lc3if.cb.INTV <=tr.INTV;
			lc3if.cb.INTP <= tr.INTP;
			while (!$root.top.LC3.ldMAR) begin
				#1;
			end
			repeat(mem_tran_num) #1;
			lc3if.cb.memory_dout <= tr.DataOut;
			lc3if.cb.MemoryMappedIO_in <= tr.MemoryMappedIO_in;
			lc3if.cb.MCR <= tr.MCR;
			lc3if.cb.memRDY <= 1;
			#1;
			lc3if.cb.memRDY <= 0;
		end
	endtask
  endclass
 
 