class Checker;
   mailbox #(MemoryTransaction) SB2Chk;
   mailbox #(MemoryTransaction) Mon2Chk;
   
   event   GenNextTrans;

   Scoreboard SB;
   
   function new ( mailbox #(MemoryTransaction) SB2Chki,
		  mailbox #(MemoryTransaction) Mon2Chki, 
		  ref event GenNextTransi,
		  Scoreboard SBi);
      SB2Chk = SB2Chki;
      Mon2Chk = Mon2Chki;
      GenNextTrans = GenNextTransi;
      SB = SBi;     
   endfunction // new

   task run (int count);
      
      MemoryTransaction SBTrans;
      MemoryTransaction MonTrans;
      MemoryTransaction EOICTrans;
      
      repeat (count) begin
	 //Block on a Transaction From Scoreboard
	 SB2Chk.get(SBTrans);
	 $display("@%0d: Checker : Received Scoreboard Trans. %0d ", $time , SBTrans.ID());
	 //Block for the Matching Transaction from the Monitor
	 Mon2Chk.get(MonTrans);
	 $display(" @%0d: Checker : Received Monitor Trans. %0d", $time , MonTrans.ID());
	 //Compare the Transactions
	 CheckTrans(SBTrans, MonTrans);
	 //Check for the End-ofInstruction Cycle  
      	 if(SB2Chk.try_get(EOICTrans)) begin
	    $display(" @%0d: Checker : Received EOIC Trans. %0d", $time , MonTrans.ID());
	    CheckState();
	 end
	 // Generate the Next Transaction
	 $display("@%0d: Checker : Transaction Complete... Triggering Generator", $time );
	 -> GenNextTrans;	 
      end
   endtask // run2
    
   task automatic  CheckState();
      string str;
      $display("@%0d:Checker: Waiting for Driver to get to Fetch0", $time);
      while($root.top.LC3.CONTROL.state != 0) begin
	$display("@%0d:Checker Waiting %0dns", $time, `CLK_PERIOD);
	#(`CLK_PERIOD/2);	 
	//$display("@%0d:Checker Waited 1 Clock Cycle", $time);
      end
      $display("@%0d:Checking DUT State against Scoreboard", $time);
      $display("Checking PC");      
      compare16(SB.PC, $root.top.LC3.DATAPATH.PC, "PC");
      $display("Checking Registers");
      foreach (SB.RegFile[i]) begin
	 str = $sformatf("Regfile[%0d]",i);
         compare16(SB.RegFile[i], $root.top.LC3.DATAPATH.REGFILE[i], str);
      end
      $display("Checking Stack Pointer");
      compare16(SB.SavedUSP, $root.top.LC3.DATAPATH.SavedUSP, "SavedUSP");
      compare16(SB.SavedSSP, $root.top.LC3.DATAPATH.SavedSSP, "SavedSSP");
      $display("Done Checking DUT's State against Scoreboard");
   endtask // CheckState

   function void compare16(bit [15:0] a, bit [15:0] b, string value);
      if(a!=b) begin
	 $display("@%0d: Checker : Bad Compare of %s", $time , value);
	 $display("Scoreboard: %04x Monitor (or DUT): %04x", a, b);
      	 $finish;
      end
   endfunction // compare16

    function void compare1(bit a, bit  b, string value);
      if(a!=b) begin
	 $display("@%0d: Checker : Bad Compare of %s", $time, value);
	 $display("Scoreboard: %d Monitor: %d", a, b);
	 $finish;
      end
   endfunction // compare16
  
   task automatic CheckTrans(MemoryTransaction fromScb, MemoryTransaction fromMon);
      if(fromScb.rst == 1'b1 || fromMon.rst == 1'b1) begin
	 if(fromScb.rst != fromMon.rst) begin
	    $display("@%0d: Checker : Reset Mismatch : Transaction Timestamp: %0d", $time, fromMon.timestamp);
	    $finish;	   
	 end
      end else begin
	 compare16(fromScb.MCR, fromMon.MCR, "MCR");
	 compare16(fromScb.Address, fromMon.Address, "Address");
	 compare16(fromScb.DataOut, fromMon.DataOut, "DataOut");	 
	 compare1(fromScb.en, fromMon.en, "en");
	 compare1(fromScb.we, fromMon.we, "we");	 
	 //Only Check when Writing to Regular Memory
	 if(fromScb.en && fromScb.we) begin
	   compare16(fromScb.DataIn, fromMon.DataIn, "DataIn");
	 end 
	 compare16(fromScb.MemoryMappedIO_in, fromMon.MemoryMappedIO_in, "MemoryMappedIO_in");
	 compare1(fromScb.MemoryMappedIO_load, fromMon.MemoryMappedIO_load, "MemoryMappedIO_load");
	 //Only Check when Writing to Memory Mapped IO
	 if(fromScb.MemoryMappedIO_load) begin
	    compare16(fromScb.MemoryMappedIO_out, fromMon.MemoryMappedIO_out, "MemoryMappedIO_out");    
	 end	 
      end
   endtask // CheckTrans
   
endclass // Checker

     