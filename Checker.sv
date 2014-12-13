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
	 $display("@%0d: Checker : Recieved SB Transaction %0d ", $time, SBTrans.id);
	 if(SBTrans.EndOfInstructionCycle)
	   CheckState();
	 else begin
	    Mon2Chk.get(MonTrans);
	    CheckTrans(SBTrans, MonTrans);
	    $display(" @%0d: Checker : Recieved MON Transaction %0d ", $time, MonTrans.id);
	 end	 
	 //Tell the Generator to 
	 // Generate the Next Transaction
	 $display("@%0d: Checker : Transaction Complete... Retiring Transaction %0d", $time, SBTrans.id);
	 -> GenNextTrans;
      end
   endtask // run2
   task automatic  CheckState();
      $display("Add Code to Check State Here!");
   endtask // CheckState

   function void compare16(bit [15:0] a, bit [15:0] b, string value);
      if(a!=b) begin
	 $display("@%0d: Checker : Bad Compare of %s", $time, value);
	 $display("Scoreboard: %04x Monitor: %04x", a, b);
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
	 compare16(fromScb.Address, fromMon.Address, "Address");
	 compare16(fromScb.DataOut, fromMon.DataOut, "DataOut");
	 compare16(fromScb.DataIn, fromMon.DataIn, "DataIn");
	 compare1(fromScb.we, fromMon.we, "we");
	 compare1(fromScb.en, fromMon.en, "en");
	 compare16(fromScb.MemoryMappedIO_in, fromMon.MemoryMappedIO_in, "MemoryMappedIO_in");
	 compare16(fromScb.MemoryMappedIO_out, fromMon.MemoryMappedIO_out, "MemoryMappedIO_out");
	 compare1(fromScb.MemoryMappedIO_load, fromMon.MemoryMappedIO_load, "MemoryMappedIO_load");
	 compare16(fromScb.MCR, fromMon.MCR, "MCR");
	 
	 
	 
      end
   endtask // CheckTrans
   
endclass // Checker

     