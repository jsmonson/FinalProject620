class Checker;
   mailbox #(MemoryTransaction) SB2Chk;
   mailbox #(MemoryTransaction) Mon2Chk;
   
   event   GenNextTrans;

   ScoreBoard SB;
   
   function new ( mailbox #(MemoryTransaction) SB2Chki,
		  mailbox #(MemoryTransaction) Mon2Chki, 
		  ref event GenNextTransi,
		  ScoreBoard SBi);
      SB2Chk = SB2Chki;
      Mon2Chk = Mon2Chki;
      GenNextTrans = GenNextTransi;
      SB = SBi;     
   endfunction // new

   function automatic void run (int count);
      
      MemoryTransaction SBTrans;
      MemoryTransaction MonTrans;
    
      repeat (count) begin
	 SB2Chk.get(SBTrans);
	 if(SBTrans.EndOfInstructionCycle)
	   CheckState();
	 else begin
	    SB2Mon.get(MonTrans);
	    CheckTrans();
	 end	 
	 //Tell the Generator to 
	 // Generate the Next Transaction
	 -> GenNextTrans;
      end
   endfunction // run

   function automatic void CheckState();
   endfunction // CheckState

   function automatic void CheckTrans();
   endfunction // CheckTrans
   
endclass // Checker

     