class Ext #(INPUT_SIZE);
   function automatic bit[15:0] SEXT(input bit [INPUT_SIZE-1:0] toExt);
      $display("");
      return { {(16-INPUT_SIZE){toExt[INPUT_SIZE-1]}}, toExt };    
   endfunction // SEXT

   function automatic bit[15:0] ZEXT(input bit [INPUT_SIZE-1:0] toExt);
      return {{(16-INPUT_SIZE){0}},toExt};
   endfunction // ZEXT
   
endclass // Extension


class Scoreboard;

   //LC3 State
   bit [15:0] RegFile[7];
   bit [15:0] PC;
   bit [15:0] PSR;
   bit [15:0] SavedUSP;
   bit [15:0] SavedSSP;

   bit 	      INT;
   bit [7:0]  INTV;
   bit [2:0]  INTP;

   bit 	      reset;
   int 	      tCount;
   event      chk2gen;
   
   MemoryTransaction CurT;
   
   //End Of Instruction Cycle Transaction
   MemoryTransaction EOIC;
   
   mailbox #(MemoryTransaction) Agt2SB;
   mailbox #(MemoryTransaction) SB2Chk;
      
   //Sign/Zero Extenders
   Ext #(5) Ext5;
   Ext #(6) Ext6;
   Ext #(8) Ext8;
   Ext #(9) Ext9;   
   Ext #(11) Ext11;
    
   function new (mailbox #(MemoryTransaction) Agt2SBi, mailbox #(MemoryTransaction) SB2Chki, ref event chk2geni);

      EOIC = new ();
      EOIC.EndOfInstructionCycle = 1'b1;
      EOIC.id = 2147483647;
      Ext5 = new();
      Ext6 = new();
      Ext8 = new();
      Ext9 = new();   
      Ext11 = new();
      
      Agt2SB = Agt2SBi;
      SB2Chk = SB2Chki;
      chk2gen = chk2geni;
      reset_sb();
   endfunction // new

   function automatic void reset_sb();
      //Start with Reset Program State
      PC = 16'd0;
      PSR = 16'd0;
      
      INT = 1'b0;
      INTV = 8'd0;
      INTP = 3'b000;

      reset = 0;
      foreach (RegFile[i])
	RegFile[i] = 16'd0;
   endfunction // reset_sb

   task automatic MbxRead();
      if(!reset || tCount > 0) begin
	 Agt2SB.get(CurT);
	 $display("@%0d: Scoreboard: Received Transaction %0d", $time, CurT.ID());
	 if(CurT.rst)
	   reset = 1'b1;
	 if(CurT.IRQ) begin
	    if(CurT.INTP > PSR[10:8]) begin
	       INT = 1'b1;
	       INTV = CurT.INTV;
	       INTP = CurT.INTP;
	    end
	 end
      end
   endtask // MbxRead

   task automatic MbxWrite();
      if(tCount > 0) begin
	 $display("@%0d: Scoreboard : Sending Transaction %0d to Checker", $time, CurT.ID());
	 SB2Chk.put(CurT);
	 tCount--;
      end
   endtask // MbxWrite

   task automatic run(int count);
      tCount = count;
      
      while ( tCount > 0) begin
	 UpdateSB();
      end
   endtask // run
   
   task automatic ReadTransaction(bit [15:0] Address);
      //Read Next Transaction
      $display("@%0d:***SB READ TRANSACTION ***", $time);
      MbxRead();     
      $display("@%0d:CurT.DataOut=%04h", $time, CurT.DataOut);      
      $display("@%0d:CurT.MMIO_load=%d", $time, CurT.MemoryMappedIO_load);      
      CurT.Address = Address;
      CurT.we = 1'b0; //Read Operation
      CurT.en = 1'b1; //Memory Enable
      CurT.MemoryMappedIO_load = 1'b0;
      if(Address == 16'hFE00 ||
	 Address == 16'hFE02 ||
	 Address == 16'hFE04 ||
	 Address == 16'hFE06) begin
	 //On MIO Read Enable Should be Low
	 CurT.en = 1'b0;
      end
     
      //Pass to Checker
      MbxWrite();    
   endtask // ReadTransaction

   task automatic WriteTransaction(bit [15:0] Address, bit [15:0] Data);
      $display("@%0d***SB WRITE TRANSACTION ***",$time);
      MbxRead();
      
      CurT.Address = Address;
      CurT.DataIn = Data;     
      CurT.we = 1'b1;
      CurT.en = 1'b1;
      CurT.MemoryMappedIO_out = Data;
      CurT.MemoryMappedIO_load = 1'b0;

      if(Address >= 16'hFE00) begin
	 CurT.MemoryMappedIO_load = 1'b1;
	 CurT.en = 1'b0;
	 CurT.we = 1'b0;
      end
     
      MbxWrite();   
   endtask // WriteTransaction
   
   
   task automatic UpdateSB();
          
     if(INT) begin
	incrPC();
	Interrupt();
     end else begin
	ReadTransaction(PC);
	incrPC();
	case (CurT.Opcode) 
	  tbBR: LC3_BR();
          tbADD: LC3_ADD();
          tbLD: LC3_LD();
	  tbST: LC3_ST();
	  tbJSR: LC3_JSR();
	  tbAND: LC3_AND();
	  tbLDR: LC3_LDR();
	  tbSTR: LC3_STR();
	  tbRTI: LC3_RTI();
	  tbNOT: LC3_NOT();
	  tbLDI: LC3_LDI();
	  tbSTI: LC3_STI();
	  tbJMP: LC3_JMP();
	  tbRES: InvalidInstructionException();
	  tbLEA: LC3_LEA();
	  tbTRAP: LC3_TRAP();
      endcase // case (I.Opcode)
     end // else: !if(CurT.INT)
    
     if(reset)
       reset_sb();

     //Send End Of Instruction Cycle Transaction
     //This tell the Checker to Compare SB and DUT State
     $display("@%0d: Scoreboard: Sending End-of-instruction-cycle Transaction", $time); 
     SB2Chk.put(EOIC);
     //Wait for Checker to Finish Comparing State
     $display("ScoreBoard Wait for Checker to Comparing State");
     @chk2gen;
	
   endtask // Update

   task automatic incrPC();
      $display("@%0d:Scoreboard: Incrementing PC to %0d", $time, PC+1);
      PC = PC + 1;
   endtask // incrPC
   
   
   task automatic setcc(bit [15:0] val);
      if(val == 16'd0) begin
	PSR[2] = 0; PSR[1] = 1; PSR[0] = 0;
      end else if (val[15] == 1'b1) begin
	PSR[2] = 1; PSR[1] = 0; PSR[0] = 0;
      end else begin
	PSR[2] = 0; PSR[1] = 0; PSR[0] = 1;
      end
   endtask // setcc

   function automatic void PrintInstr(string label, bit [15:0] op1, bit [15:0] op2, bit [15:0] op3);
      $display("@%0d: SB INSTRUCTION: %s, op1: %04x, op2 %04x", $time, label, op1, op2, op3);
   endfunction // PrintInstr
   
   
   task automatic LC3_ADD();
                
      if(CurT.DataOut[5]==0) begin
	 //Register Mode
	 PrintInstr("ADD", CurT.DR(), CurT.SR1(), CurT.SR2());
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] + RegFile[CurT.SR2()];
      end else begin
         //Immediate Mode
	 PrintInstr("ADD", CurT.DR(), CurT.SR1(), CurT.imm5());
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] + Ext5.SEXT(CurT.imm5());
      end
	 
      setcc(RegFile[CurT.DR()]);
	
   endtask // LC3_ADD
  
   
   task automatic  LC3_AND();
           
      if(CurT.DataOut[5]==0) begin
	 //Register Mode
	 PrintInstr("AND", CurT.DR(), CurT.SR1(), CurT.SR2());
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] & RegFile[CurT.SR2()];
      end else begin
         //Immediate Mode
	 PrintInstr("AND", CurT.DR(), CurT.SR1(), CurT.imm5());
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] & Ext5.SEXT(CurT.imm5());
      end
	 
      setcc(RegFile[CurT.DR()]);
	
   endtask // LC3_AND

   task automatic LC3_BR();
      PrintInstr("BR", CurT.DR(), CurT.PCoffset9(), 16'd0);
      if((CurT.n() && PSR[2]) || (CurT.z() && PSR[1]) || (CurT.p() && PSR[0]))
	PC = PC + Ext9.SEXT(CurT.PCoffset9());
   endtask // LC3_BR
   
   task automatic LC3_JMP();
      //This also covers RET
      PrintInstr("JMP", CurT.BaseR(), 16'bx, 16'bx);
      PC = RegFile[CurT.BaseR()];
   endtask // LC3_JMP

   task automatic LC3_JSR();
  
      RegFile[7] = PC;
      if(CurT.DataOut[11]==0) begin
	PC = RegFile[CurT.BaseR()];
	PrintInstr("JSRR", CurT.BaseR(), 16'bx, 16'bx);
      end else begin
	PrintInstr("JSR", PC, CurT.PCoffset11(), 16'bx);
	PC = PC + Ext11.SEXT(CurT.PCoffset11());
      end
   endtask // LC3_JSR

   task automatic LC3_LD();
      PrintInstr("LD", CurT.DR(), CurT.PCoffset9(), 16'bx);
      ReadTransaction(PC + Ext9.SEXT(CurT.PCoffset9()));
      RegFile[CurT.DR()] = CurT.DataOut;
      setcc(CurT.DataOut);
   endtask // LC3_LD

   task automatic LC3_LDI();
      ReadTransaction(PC+Ext9.SEXT(CurT.PCoffset9()));
      ReadTransaction(CurT.DataOut);
      RegFile[CurT.DR()] = CurT.DataOut;
      setcc(CurT.DataOut);
   endtask // LC3_LDI

   task automatic LC3_LDR();
      PrintInstr("LDR", CurT.DR(), CurT.BaseR(), CurT.offset6());
      ReadTransaction(RegFile[CurT.BaseR()]+Ext6.SEXT(CurT.offset6));
      RegFile[CurT.DR()] = CurT.DataOut;
      setcc(CurT.DataOut);
   endtask // LC3_LDR

   task automatic LC3_LEA();
      PrintInstr("LEA", CurT.DR(), CurT.PCoffset9(), 16'bx);
      RegFile[CurT.DR()] = PC + Ext9.SEXT(CurT.PCoffset9());
      setcc(RegFile[CurT.DR()]);
   endtask // LC3_LDR

   task automatic LC3_NOT();
      PrintInstr("NOT", CurT.DR(), CurT.SR(), 16'bx);
      RegFile[CurT.DR()] = ~RegFile[CurT.SR()];
      setcc(RegFile[CurT.DR()]);
   endtask // LC3_NOT

   task automatic LC3_ST();
      PrintInstr("ST", CurT.SR(), CurT.PCoffset9(), 16'bx);
      WriteTransaction(PC + Ext9.SEXT(CurT.PCoffset9()), RegFile[CurT.SR()]);
   endtask // LC3_ST

   task automatic LC3_STI();
      PrintInstr("STI", CurT.SR(),CurT.PCoffset9(), 16'bx);
      ReadTransaction(PC + Ext9.SEXT(CurT.PCoffset9()));
      WriteTransaction(CurT.DataOut, RegFile[CurT.SR()]);
   endtask // LC3_STI

   task automatic LC3_STR();
      PrintInstr("STR", CurT.SR(), CurT.BaseR(), CurT.offset6());
      WriteTransaction(RegFile[CurT.BaseR()] + Ext6.SEXT(CurT.offset6()), RegFile[CurT.SR()]);
   endtask // LC3_STR

   task automatic LC3_TRAP();
      PrintInstr("TRAP", CurT.trapvect8(), 16'bx, 16'bx);
      RegFile[7] = PC;
      ReadTransaction(Ext8.ZEXT(CurT.trapvect8));
      PC = CurT.DataOut;
   endtask // LC3_TRAP

   task automatic LC3_RTI();
      
      bit [15:0] TEMP;
      PrintInstr("RTI", 16'bx, 16'bx, 16'bx);
      if(PSR[15] == 0) begin
	 ReadTransaction(RegFile[6]);
	 PC = CurT.DataOut;
	 RegFile[6] = RegFile[6] + 1;
	 ReadTransaction(RegFile[6]);
	 TEMP = CurT.DataOut;
	 RegFile[6] = RegFile[6] + 1;
	 PSR = TEMP;
      end else
	 PriveledgeModeException();
      	 
   endtask // LC3_RTI

   task automatic SetSupervisorMode();
      PSR[15] = 1'b0;
   endtask // SetSupervisorMode

   task automatic SetUserMode();
      PSR[15] = 1'b1;
   endtask // SetUserMode
      
   task automatic SaveUSPLoadSSP();
      //Save the User Stack Pointer
      SavedUSP = RegFile[6];
      //Load the Supervisor Stack Pointer
      RegFile[6] = SavedSSP;
   endtask // SaveUSPLoadSSP
   
   task automatic SavePSRAndPCLoadVector(bit [15:0] Vector);
      //Decrement SSP
      RegFile[6] = RegFile[6] - 1;
      //Put the PSR on the Supervisor Stack
      WriteTransaction(RegFile[6], PSR);
      //Decrement SSP
      RegFile[6] = RegFile[6] - 1;
      //Put the PC on the Supervisor Stack
      WriteTransaction(RegFile[6], PC-1);
      //Update PC With Interrupt or Exception Vector
      ReadTransaction(Vector);
      PC = CurT.DataOut;
   endtask
      
   task automatic Interrupt();
      
      if(PSR[15] == 1'b1) begin
	 SaveUSPLoadSSP();
      end

      SavePSRAndPCLoadVector(INTV);

      //Update PSR Priority
      PSR[10:8] = INTP;
      
      SetSupervisorMode();
                 
   endtask // Interrupt
	 
   task automatic PriveledgeModeException();
      SaveUSPLoadSSP();
      SavePSRAndPCLoadVector(16'h0100);
      SetSupervisorMode();      
   endtask // PriveledgeModeException

   task automatic InvalidInstructionException();
      if(PSR[15] == 1'b1) begin
	 SaveUSPLoadSSP();
      end
      SavePSRAndPCLoadVector(16'h0101);
      SetSupervisorMode();
   endtask // InvalidInstructionException
     
   
   //Write Exception Handlers and 
      
   
endclass // Scoreboard
