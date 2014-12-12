class Monitor;
   
   vLC3if lc3if;
   int tCount;
   
   mailbox #(MemoryTransaction) Mon2Chk;
   MemoryTransaction toSend;
    
   function new(mailbox #(MemoryTransaction) Mon2Chki, vLC3if lc3ifi);
      Mon2Chk = Mon2Chki;
      lc3if = lc3ifi;
   endfunction // new

   task SendToChecker(MemoryTransaction T);
      $display("@%0d: Monitor Sending Transaction to Checker", $time);
      T.timestamp = $time;
      tCount--;
      Mon2Chk.put(T);
   endtask // SendToChecker
      
   task run(int count);
      tCount = count;
       while (tCount > 0) begin
	 
	 if(lc3if.rst) begin
<<<<<<< HEAD
	    //Wait for the Reset to fall
	    while(lc3if.rst) #1;
	    //Create a Reset Transaction and Send it.
=======
>>>>>>> 7ec97433358c45c193517e9def6f8cc52e34452e
	    toSend = new ();
	    toSend.rst = 1'b1;	    
	    SendToChecker(toSend);
	 end else if (lc3if.memRDY) begin
	    toSend = new ();
	    toSend.Address = lc3if.memory_addr;
            toSend.DataOut = lc3if.memory_dout;
	    toSend.DataIn =  lc3if.memory_din;
	    toSend.we =  lc3if.memWE;
            toSend.en =  lc3if.memEN; 
	    toSend.rst = 1'b0;
	    
	    toSend.IRQ  =  lc3if.IRQ;
	    toSend.INTV =  lc3if.INTV;
	    toSend.INTP =  lc3if.INTP;
      
            //Memory Mapped I/O Signals
	    toSend.MemoryMappedIO_in  =  lc3if.MemoryMappedIO_in;
	    toSend.MemoryMappedIO_out =  lc3if.MemoryMappedIO_out;
	    toSend.MemoryMappedIO_load = lc3if.MemoryMappedIO_load;
	  
	    SendToChecker(toSend);
     
	 end // if ($root.top.DUT.memRDY)

	 #1; //Wait one cycle
      end 
   endtask // run

endclass // Monitor

   
	
      