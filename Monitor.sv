class Monitor;
   
   vLC3if lc3if;
   int tCount;
   int clock_period;
   int id;
   
   bit wait_on_rst;
   
   mailbox #(MemoryTransaction) Mon2Chk;
   mailbox #(MemoryTransaction) Drv2Mon;
   
   MemoryTransaction toSend;
   MemoryTransaction rstTrans;
 
   function new(mailbox #(MemoryTransaction) Mon2Chki, vLC3if lc3ifi, int clock_periodi, 
		mailbox #(MemoryTransaction) Drv2Moni);
      id =0;
      Mon2Chk = Mon2Chki;
      lc3if = lc3ifi;
      clock_period = clock_periodi;
      Drv2Mon = Drv2Moni;
      wait_on_rst = 0;
   endfunction // new

   task SendToChecker(MemoryTransaction T);
      $display("@%0d: Monitor Sending Transaction %0d to Checker", $time, T.ID());
      T.timestamp = $time;
      tCount--;
      Mon2Chk.put(T);
   endtask // SendToChecker
      
   task run(int count);
      tCount = count;
           
      while (tCount > 0) begin
	 if(Drv2Mon.try_get(rstTrans)) begin
	    $display("@%0d: Monitor: Setting wait_on_rst", $time);
	    wait_on_rst = 1'b1;
	 end
	 if(lc3if.rst) begin
	    //Wait for the Reset to fall
	    $display("@%0d: Monitor See Reset Signal", $time);
	    while(lc3if.rst) #(`CLK_PERIOD/2);
	    //Create a Reset Transaction and Send it.
	    $display("@%0d: Monitor Found Reset Transaction", $time);
	    toSend = new ();
	    toSend.rst = 1'b1;
	    toSend.id = id++;
	    wait_on_rst = 0;
	    SendToChecker(toSend);
	 end else if (lc3if.memRDY && !wait_on_rst) begin
	    toSend = new ();
	    toSend.id = id++;
	    
	    toSend.MCR = lc3if.MCR;
	    toSend.Address = lc3if.memory_addr;
            toSend.DataOut = lc3if.memory_dout;
	    if(lc3if.memWE && lc3if.memEN)
	      toSend.DataIn =  lc3if.memory_din;
	    toSend.we =  lc3if.memWE;
            toSend.en =  lc3if.memEN; 
	    toSend.rst = 1'b0;
	    
	    toSend.IRQ  =  lc3if.IRQ;
	    toSend.INTV =  lc3if.INTV;
	    toSend.INTP =  lc3if.INTP;
      
            //Memory Mapped I/O Signals
	    toSend.MemoryMappedIO_in  =  lc3if.MemoryMappedIO_in;
	    if(lc3if.MemoryMappedIO_load)
	      toSend.MemoryMappedIO_out =  lc3if.MemoryMappedIO_out;
	    toSend.MemoryMappedIO_load = lc3if.MemoryMappedIO_load;

	    SendToChecker(toSend);    
     
	 end // if ($root.top.DUT.memRDY)

	 #(`CLK_PERIOD); //Wait one cycle
      end 
   endtask // run

endclass // Monitor

   
	
      