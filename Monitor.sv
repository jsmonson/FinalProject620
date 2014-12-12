class Monitor;
   
   vLC3if lc3if;
   
   mailbox #(MemoryTransaction) Mon2Chk;
   MemoryTransaction toSend;
    
   function new(mailbox #(MemoryTransaction) Mon2Chki, vLC3if lc3ifi);
      Mon2Chk = Mon2Chki;
      lc3if = lc3ifi;
   endfunction // new

   task run(int count);
      forever begin
	 
	 if($root.top.DUT.rst) begin
	    toSend = new ();
	    toSend.rst = 1'b1;
	    Mon2Chk.put(toSend);
	 end else if ($root.top.DUT.memRDY) begin
	    
	    toSend = new ();
	    toSend.Address = $root.top.DUT.Address;
            //toSend.DataOut =  $root.top.DUT.;
            //toSend.DataIn =  $root.top.DUT.;
	    //toSend.we =  $root.top.DUT.;
            //toSend.en = $root.top.DUT. ; 
	    //toSend.rst = 1'b0;
	    
	    //toSend.IRQ  =  $root.top.DUT.;
	    //toSend.INTV =  $root.top.DUT.;
	    //toSend.INTP =  $root.top.DUT.;
      
            //Memory Mapped I/O Signals
	    //toSend.MemoryMappedIO_in  =  $root.top.DUT.;
	    //toSend.MemoryMappedIO_out =  $root.top.DUT.;
	    //toSend.MemoryMappedIO_load = $root.top.DUT.;
	  
	    Mon2Chk.put(toSend);
     
	 end // if ($root.top.DUT.memRDY)

	 #1; //Wait one cycle
      end 
   endtask // run

endclass // Monitor

   
	
      