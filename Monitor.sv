class Monitor;
   
   vLC3if lc3if;
   int tCount;
   
   mailbox #(MemoryTransaction) Mon2Chk;
   MemoryTransaction toSend;
    
   function new(mailbox #(MemoryTransaction) Mon2Chki, vLC3if lc3ifi);
      Mon2Chk = Mon2Chki;
      lc3if = lc3ifi;
   endfunction // new

   function automatic void SendToChecker(MemoryTransaction T);
      $display("@%0d: Monitor Sending Transaction to Checker", $time);
      T.timestamp = $time;
      tCount--;
      Mon2Chk.put(T);
   endfunction // SendToChecker
      
   task run(int count);
      tCount = count;
       while (tCount > 0) begin
	 
	 if(lc3if.cb.rst) begin
	    toSend = new ();
	    toSend.rst = 1'b1;	    
	    SendToChecker(toSend);
	 end else if (lc3if.cb.memRDY) begin
	    
	    toSend = new ();
	    toSend.Address = lc3if.cb.memory_addr;
            toSend.DataOut = lc3if.cb.memory_dout;
	    toSend.DataIn =  lc3if.cb.memory_din;
	    toSend.we =  lc3if.cb.memWE;
            toSend.en =  lc3if.cb.memEN; 
	    toSend.rst = 1'b0;
	    
	    toSend.IRQ  =  lc3if.cb.IRQ;
	    toSend.INTV =  lc3if.cb.INTV;
	    toSend.INTP =  lc3if.cb.INTP;
      
            //Memory Mapped I/O Signals
	    toSend.MemoryMappedIO_in  =  lc3if.cb.MemoryMappedIO_in;
	    toSend.MemoryMappedIO_out =  lc3if.cb.MemoryMappedIO_out;
	    toSend.MemoryMappedIO_load = lc3if.cb.MemoryMappedIO_load;
	  
	    SendToChecker(toSend);
     
	 end // if ($root.top.DUT.memRDY)

	 #1; //Wait one cycle
      end 
   endtask // run

endclass // Monitor

   
	
      