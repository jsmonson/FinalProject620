class Monitor;

   mailbox #(MemoryTransaction) Mon2Chk;
   MemoryTransation toSend;
    
   function new(mailbox #(MemoryTransaction) Mon2Chki);
      Mon2Chk = Mon2Chki;
   endfunction // new

   function run();
      forever begin
	 
	 if($root.top.DUT.rst) begin
	    toSend = new ();
	    toSend.rst = 1'b1;
	    Mon2Chk.put(toSend);
	 end else if ($root.top.DUT.memRDY) begin
	    
	    toSend = new ();
	    toSend.Address = $root.top.DUT.Address;
            toSend.DataOut =  $root.top.DUT.;
            toSend.DataIn =  $root.top.DUT.;
	    toSend.we =  $root.top.DUT.;
            toSend.en = $root.top.DUT. ; 
	    toSend.rst = 1'b0;
	    
	    toSend.IRQ  =  $root.top.DUT.;
	    toSend.INTV =  $root.top.DUT.;
	    toSend.INTP =  $root.top.DUT.;
      
            //Memory Mapped I/O Signals
	    toSend.MemoryMappedIO_in  =  $root.top.DUT.;
	    toSend.MemoryMappedIO_out =  $root.top.DUT.;
	    toSend.MemoryMappedIO_load = $root.top.DUT.;
	  
	    Mon2Chk.put(toSend);
     
	 end // if ($root.top.DUT.memRDY)

	 #1; //Wait one cycle
      end 
   endfunction // run

endclass // Monitor

   
	
      