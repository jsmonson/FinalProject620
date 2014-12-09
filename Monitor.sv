class Monitor;

   mailbox #(MemoryTransaction) Mon2Chk;
   MemoryTransation toSend;
    
   function new();
   endfunction // new

   function run();
      forever begin
	 //When the Initiates a Memory Transaction
	 if($root.DUT.ldMAR == 1'b1) begin
	    //Wait 1 Cycle
	    #1;
	    
	 end
	 
      end
      
   endfunction // run
   
	
      