class Driver;
      mailbox #(MemoryTransaction) agt2drv;
      MemoryTransaction tr;
	  int mem_tran_num;
      function new(input mailbox #(MemoryTransaction) agt2drv, input int mem_tran_num);
        this.agt2drv = agt2drv;
		this.mem_tran_num = mem_tran_num;
	  endfunction
      task run(input int count);
		repeat(count) begin
			agt2drv.get(tr);
			@$root.top.lc3_if.cb;
			if (tr.rst) begin
				$root.top.lc3_if.rst <= 1'b1;
				repeat(tr.reset_cycles)@$root.top.lc3_if.cb;
			end
			else begin
				$root.top.IRQ <= tr.IRQ;
				$root.top.INTV <=tr.INTV;
				$root.top.INTP <= tr.INTP;
				while (!$root.top.LC3.ldMAR) begin
					@$root.top.lc3_if.cb;
				end
				repeat(mem_tran_num)@$root.top.lc3_if.cb;
				$root.top.lc3_if.memory_dout <= tr.DataOut;
				$root.top.lc3_if.MemoryMappedIO_in <= tr.MemoryMappedIO_in;
				$root.top.lc3_if.MCR <= tr.MCR;
				$root.top.lc3_if.memRDY <= 1;
				@$root.top.lc3_if.cb;
				$root.top.lc3_if.memRDY <= 0;
			end
		end 
    endtask
  endclass