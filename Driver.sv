class Driver;
      mailbox #(MemoryTransaction) agt2drv;
      MemoryTransaction tr;
      event agt2drvhs; // mailbox synchronization
      function new(input mailbox #(MemoryTransaction) agt2drv, input event agt2drvhs);
        this.agt2drv = agt2drv;
        this.agt2drvhs = agt2drvhs;
	  endfunction
      task run(input int count);
		repeat(count) begin
			agt2drv.get(tr);
			@$root.top.lc3_if.cb;
			if (tr.rst)
				$root.top.lc3_if.rst <= 1'b1;
			else begin
				$root.top.lc3_if.rst <= 1'b0;
				if ($root.top.LC3.ldMAR)
					$root.top.lc3_if.memory_dout <= tr.DataOut;
			end
			->agt2drvhs; // tell agent that transaction has been driven onto DUT
		end 
    endtask
  endclass