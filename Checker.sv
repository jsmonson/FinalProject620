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
    
      repeat (count) begin
	 SB2Chk.get(SBTrans);
	 $display("@%0d: Checker : Recieved from Scoreboard ", $time);
	 if(SBTrans.EndOfInstructionCycle)
	   CheckState();
	 else begin
	    Mon2Chk.get(MonTrans);
	    CheckTrans(SBTrans, MonTrans);
	    $display(" @%0d: Checker : Recieved from Monitor ", $time);
	 end	 
	 //Tell the Generator to 
	 // Generate the Next Transaction
	 $display("Sending Generate Next Transaction");
	 -> GenNextTrans;
      end
   endtask // run2
   task automatic  CheckState();
   endtask // CheckState
   
   task automatic CheckTrans(MemoryTransaction fromScb, MemoryTransaction fromMon);
      if(fromScb.rst == 1'b1 || fromMon.rst == 1'b1) begin
	 if(fromScb.rst != fromMon.rst) begin
	    $display("@%0d: Checker : Reset Mismatch : Transaction Timestamp: %0d", $time, fromMon.timestamp);
	 end
      end else begin
	 $display("Compare Transactions");
	 
      end
   endtask // CheckTrans
   
endclass // Checker

     