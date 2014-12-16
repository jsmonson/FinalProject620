virtual class Driver_cbs;
    virtual task pre_tx(ref MemoryTransaction t);
    endtask 
    virtual task post_tx(ref MemoryTransaction t);
    endtask 
  endclass 
  
class Driver;
      mailbox #(MemoryTransaction) agt2drv;
      bit 	      first_transaction_happened;
   
      MemoryTransaction tr;
	  Driver_cbs cbs[$];
	  int mem_tran_num;
	  logic [3:0] opcode;
	  event chk2gen;
	  vLC3if lc3if;
      function new(input mailbox #(MemoryTransaction) agt2drv, input int mem_tran_num, vLC3if lc3if, ref event chk2geni);
        this.agt2drv = agt2drv;
		this.mem_tran_num = mem_tran_num;
		this.lc3if = lc3if;
	 first_transaction_happened = 0;
	 chk2gen = chk2geni;
	 
	  endfunction
      task run(input int count);
	    repeat(5) @lc3if.cb; // reset
		repeat(count) begin			
			while (!$root.top.LC3.ldMAR && $root.top.LC3.CONTROL.state != 0) begin // f0
			   $display("@%0d: Driver: Stepping Clock", $time);
			    @lc3if.cb;			   
			end
		       //$display("@%0d: Driver: DUT Current State: %0d ldMAR=%0d", $time, $root.top.LC3.CONTROL.state,$root.top.LC3.ldMAR);
		       if(!$root.top.LC3.CONTROL.state && first_transaction_happened) begin
			  $display("@%0d:DRIVER: In FETCH0, waiting for Checker to Synchronize",$time);
			  @(chk2gen);
		     
			  $display("@%0d:DRIVER: Received chk2gen", $time);
		       end 
		       
		       if ($root.top.LC3.ldMAR) begin
			   agt2drv.get(tr);
			   foreach(cbs[i]) cbs[i].pre_tx(tr); // callbacks
			   first_transaction_happened = 1;
		      	   transmit(tr);
			   foreach (cbs[i]) cbs[i].post_tx(tr);
			end 
		end
    endtask
	/*task init_reset(input int count);
		lc3if.rst <= 1'b1;
		repeat(count) @lc3if.cb;
		lc3if.rst <= 1'b0;
	endtask*/
	task transmit(MemoryTransaction tr);
		@lc3if.cb;
		$display("@%0d: Driver: Driving Transaction %d",$time, tr.ID());
		if (tr.rst) begin
			$display("@%0t: Reset!",$time);
			lc3if.rst <= 1'b1;
			repeat(tr.reset_cycles) @lc3if.cb;
		end
		else begin
			repeat(mem_tran_num) @lc3if.cb;
			lc3if.cb.IRQ <= tr.IRQ;
			lc3if.cb.INTV <=tr.INTV;
			lc3if.cb.INTP <= tr.INTP;
			opcode = lc3if.memory_dout[15:12];
			lc3if.cb.memory_dout <= tr.DataOut;
			lc3if.cb.MemoryMappedIO_in <= tr.MemoryMappedIO_in;
			lc3if.cb.MCR <= tr.MCR;
			lc3if.cb.memRDY <= 1;
			@lc3if.cb;
			lc3if.cb.memRDY <= 0;
		end
	endtask
  endclass
 
 