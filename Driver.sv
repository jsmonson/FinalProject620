class Driver;
      mailbox #(MemoryTransaction) agt2drv;
      MemoryTransaction tr;
      function new(input mailbox #(MemoryTransaction) agt2drv);
        this.agt2drv = agt2drv;
	  endfunction
      task run(input int count);
		repeat(count) begin
			agt2drv.get(tr);
			@$root.top.lc3_if.cb;
			if (tr.rst) begin
				$root.top.lc3_if.rst <= 1'b1;
				(tr.reset_cycles)@$root.top.lc3_if.cb;
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
				memRDY <= 1;
				@$root.top.lc3_if.cb;
				memRDY <= 0;
			end
		end 
    endtask
  endclass