class #(INPUT_SIZE) Ext;
   function automatic bit[15:0] SEXT(input bit [INPUT_SIZE-1:0] toExt);
      return { {(16-INPUT_SIZE){toExt[INPUT_SIZE-1]}, toExt} };    
   endfunction // SEXT

   function automatic bit[15:0] ZEXT(input bit [INPUT_SIZE-1:0] toExt);
      return {{(16-INPUT_SIZE){0},toExt}};
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

   MemoryTransaction CurT;
      
   mailbox #(MemoryTransaction) Agt2SB;
   mailbox #(MemoryTransaction) SB2Chk;
      
   //Sign/Zero Extenders
   Ext #(5) Ext5;
   Ext #(6) Ext6;
   Ext #(8) Ext8;
   Ext #(9) Ext9;   
   Ext #(11) Ext11;
    
   function new (mailbox #(MemoryTransaction) Agt2SBi, SB2Chki);
      
      Agt2SB = Agt2SBi;
      SB2Chk = SB2Chki;
      
      reset_sb();
   endfunction // new

   function automatic void reset_sb();
      //Start with Reset Program State
      PC = 16'd0;
      PSR = 16'd0;
      
      INT = 1'b0;
      INTV = 8'd0;
      INTP = 2'b000;

      reset = 0;
      foreach RegFile[i]
	RegFile[i] = 16'd0;
   endfunction // reset_sb

   function automatic void MbxRead();
      if(!reset) begin
	 Agt2SB.get(CurT);
	 if(CurT.reset)
	   reset = 1'b1;
	 if(CurT.IRQ) begin
	    if(CurT.INTP > PSR[10:8]) begin
	       INT = 1'b1;
	       INTV = CurT.INTV;
	       INTP = CurT.INTP;
	    end
	 end
      end
   endfunction // MbxRead

   function automatic void MbxWrite();
      SB2Chk.put(CurT);
   endfunction // MbxWrite

   function automatic void run(int InstructionCycles);
      repeat(InstructionCycles) begin
	 UpdateSB();
      end
   endfunction // run
   
   
   function automatic void ReadTransaction(bit [15:0] Address);
      //Read Next Transaction
      MbxRead();
      CurT.Address = Address;
      CurT.WE = 1'b0; //Read Operation
      CurT.EN = 1'b1; //Memory Enable
      if(Address == 16'hFE00 ||
	 Address == 16'hFE02 ||
	 Address == 16'hFE04 ||
	 Address == 16'hFE06) begin
	 //On MIO Read Enable Should be Low
	 CutT.EN = 1'b0;
      end
      //Pass to Checker
      MbxWrite();    
   endfunction // ReadTransaction

   function automatic void WriteTransaction(bit [15:0] Address, bit [15:0] Data);
      MbxRead();
      CurT.Address = Address;
      CurT.DataIn = Data;     
      CurT.WE = 1'b1;
      CurT.EN = 1'b1;
      if(Address == 16'hFE00) begin
	 //KeyBoard Status Register Write
	 CurT.EN = 1'b0;
	 CurT.ldKBSR = 1'b1;
	 CurT.KBSRo = Data;
      end else if (Address == 16'hFE02) begin
	 //Keyboard Data Register
	 CurT.EN = 1'b0;
      end else if (Address == 16'hFE04) begin
	 //Display Status Register
	 CurT.EN = 1'b0;
	 CurT.ldDSR = 1'b1;
	 CurT.DSRo = Data;	 
      end else if (Address == 16'hFE06) begin
	 //Display Data Register
	 CurT.EN = 1'b0;
	 CurT.ldDDR = 1'b1;
	 CurT.DDR = Data;
      end
      //Pass to Checker
      MbxWrite();   
   endfunction // WriteTransaction
   
   
   function automatic void UpdateSB();
          
     if(INT) begin
	incrPC();
	LC3_INT();
     else begin
	ReadTransaction(PC);
	incrPC();
	case (CurT.Opcode) 
	  BR: LC3_BR();
          ADD: LC3_ADD();
          LD: LC3_LD();
	  ST: LC3_ST();
	  JSR: LC3_JSR();
	  AND: LC3_AND();
	  LDR: LC3_LDR();
	  STR: LC3_STR();
	  RTI: ;
	  NOT: LC3_NOT();
	  LDI: LC3_LDI();
	  STI: LC3_STI();
	  JMP: LC3_JMP();
	  RES: ;
	  LEA: LC3_LEA();
	  TRAP: LC3_TRAP();
      endcase // case (I.Opcode)
     end // else: !if(CurT.INT)
    
     if(reset)
       reset_sb();
	
   endfunction // Update

   function automatic void incrPC();
      PC = PC + 1;
   endfunction // incrPC
   
   
   function automatic void setcc(bit [15:0] val);
      if(val == 16'd0)
	PSR[2] = 0; PSR[1] = 1; PSR[0] = 0;
      else if (val[15] == 1'b1)
	PSR[2] = 1; PSR[1] = 0; PSR[0] = 0;
      else
	PSR[2] = 0; PSR[1] = 0; PSR[0] = 1;
   endfunction // setcc
      
   function automatic void LC3_ADD();
      
      if(CurT.DataOut[5]==0) begin
	 //Register Mode
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] + RegFile[CurT.SR2()];
      end else begin
         //Immediate Mode
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] + Ext5.SEXT(CurT.imm5());
      end
	 
      setcc(RegFile[CurT.DR()]);
	
   endfunction // LC3_ADD

   function automatic void LC3_AND();
       
      if(CurT.instr[5]==0) begin
	 //Register Mode
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] & RegFile[CurT.SR2()];
      end else begin
         //Immediate Mode
	 RegFile[CurT.DR()] = RegFile[CurT.SR1()] & Ext5.SEXT(CurT.imm5());
      end
	 
      setcc(RegFile[CurT.DR()]);
	
   endfunction // LC3_AND

   function automatic void LC3_BR()
      if((CurT.n() && PSR[2]) || (CurT.z() && PSR[1]) || (CurT.p() && PSR[0]))
	PC = PC + Ext9.SEXT(CurT.PCoffset9());
   endfunction // LC3_BR
   
   function automatic void LC3_JMP();
      //This also covers RET
      PC = RegFile[CurT.BaseR()];
   endfunction // LC3_JMP

   function automatic void LC3_JSR();
      RegFile[7] = PC;
      if(CurT.DataOut[11]=1)
	PC = CurT.BaseR();
      else
	PC = PC + Ext11.SEXT(CurT.PCoffset11());
      
   endfunction // LC3_JSR

   function automatic void LC3_LD();
      ReadTransaction(PC + Ext9.SEXT(CurT.PCoffset9()));
      RegFile[CurT.DR()] = CurT.DataOut;
      setcc(CurT.DataOut);
   endfunction // LC3_LD

   function automatic void LC3_LDI();
      ReadTransaction(PC+Ext9.SEXT(CurT.PCoffset9()));
      ReadTransaction(CurT.DataOut);
      RegFile[CurT.DR()] = CurT.DataOut;
      setcc(CurT.DataOut);
   endfunction // LC3_LDI

   function automatic void LC3_LDR();
      ReadTransaction(CurT.BaseR()+Ext6.SEXT(CurT.offset6));
      RegFile[CurT.DR()] = CurT.DataOut;
      setcc(CurT.DataOut);
   endfunction // LC3_LDR

   function automatic void LC3_LDR();
      RegFile[CurT.DR()] = PC + Ext9.SEXT(CurT.PCoffset9());
      setcc(RegFile[CurT.DR()]);
   endfunction // LC3_LDR

   function automatic void LC3_NOT();
      RegFile[CurT.DR()] = ~RegFile[CurT.SR()];
      setcc(RegFile[CurT.DR()]);
   endfunction // LC3_NOT

   function automatic void LC3_ST();
      WriteTransaction(PC + Ext9.SEXT(CurT.PCoffset9()), RegFile[CurT.SR()]);
   endfunction // LC3_ST

   function automatic void LC3_STI();
      ReadTransaction(PC + Ext9.SEXT(CurT.PCoffset9()));
      WriteTransaction(CurT.DataOut, RegFile[CurT.SR()]);
   endfunction // LC3_STI

   function automatic void LC3_STR();
      WriteTransaction(CurT.BaseR() + Ext6.SEXT(CurT.offset6), RegFile[CurT.SR()]);
   endfunction // LC3_STR

   function automatic void LC3_TRAP();
      RegFile[7] = PC;
      ReadTransaction(Ext8.ZEXT(CurT.trapvect8));
      PC = CurT.DataOut;
   endfunction // LC3_TRAP

   function automatic void LC3_RTI();
      bit [15:0] TEMP;
      
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
      
	 //Initiate the Priviledge Mode Exception
   endfunction // LC3_RTI



   function automatic void SaveUSPLoadSSP();
      //Save the User Stack Pointer
      SavedUSP = RegFile[6];
      //Load the Supervisor Stack Pointer
      RegFile[6] = SavedSSP;
   endfunction // SaveUSPLoadSSP
   
   function automatic void SavePSRAndPCLoadVector(bit [15:0] Vector);
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
   end // if (INT)
      
   function automatic void Interrupt();
      if(PSR[15] == 1'b1) begin
	 //LC3 in User Mode
	 //Switch to Supervisor Mode
	 PSR[15] = 1'b0;
	 //Save the User Stack Pointer
	 SavedUSP = RegFile[6];
	 //Load the Supervisor Stack Pointer
	 RegFile[6] = SavedSSP;
      end
      //Decrement SSP
      RegFile[6] = RegFile[6] - 1;
      //Put the PSR on the Supervisor Stack
      WriteTransaction(RegFile[6], PSR);
      //Decrement SSP
      RegFile[6] = RegFile[6] - 1;
      //Put the PC on the Supervisor Stack
      WriteTransaction(RegFile[6], PC-1);
            
      PSR[10:8] = INTP;
     
   endfunction // Interrupt
	 
   function automatic void PriveledgeModeException();
   endfunction // PriveledgeModeException

   function automatic void InvalidInstructionException();
   endfunction // InvalidInstructionException
     
   
   //Write Exception Handlers and 
      
   
endclass // Scoreboard
