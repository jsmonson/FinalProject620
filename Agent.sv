class Agent;
      mailbox #(MemoryTransaction) gen2agt, agt2drv, agt2scb;
      MemoryTransaction tr;
      event agt2scbhs;
      function new(input mailbox #(MemoryTransaction) gen2agt, agt2drv, agt2scb, input event agt2scbhs);
        this.gen2agt = gen2agt;
        this.agt2drv = agt2drv;
		this.agt2scb = agt2scb;
		this.agt2scbhs = agt2scbhs;
      endfunction
      task run(int count);
        repeat(count) begin
            gen2agt.get(tr);
			agt2drv.put(tr);
            wait (agt2scbhs.triggered);
            agt2drv.put(tr);         
        end
      endtask
  endclass