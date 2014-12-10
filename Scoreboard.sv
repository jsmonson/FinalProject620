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
   bit N,Z,P;

   mailbox #(MemoryTransaction) Agt2SB;
   mailbox #(MemoryTransaction) SB2Chk;
      
   //Sign/Zero Extenders
   Ext #(5) Ext5;
   Ext #(6) Ext6;
   Ext #(8) Ext8;
   Ext #(9) Ext9;   
   Ext #(11) Ext11;
    
   function new ();
      reset_sb();
   endfunction // new

   function reset_sb();
      //Start with Reset Program State
      PC = 16'd0;
      NZP = 3'b000;
      foreach RegFile[i]
	RegFile[i] = 16'd0;
   endfunction // reset_sb
   
   function automatic void Update(Instruction I);
      incrPC();
      case (I.Opcode) 
	BR: LC3_BR(I);
        ADD: LC3_ADD(I);
        LD: LC3_LD(I);
	ST: LC3_ST(I);
	JSR: LC3_JSR(I);
	AND: LC3_AND(I);
	LDR: LC3_LDR(I);
	STR: LC3_STR(I);
	RTI: ;
	NOT: LC3_NOT(I);
	LDI: LC3_LDI(I);
	STI: LC3_STI(I);
	JMP: LC3_JMP(I);
	RES: ;
	LEA: LC3_LEA(I);
	TRAP: LC3_TRAP(I);
      endcase // case (I.Opcode)
      
   endfunction // Update

   function automatic void incrPC();
      PC = PC + 1;
   endfunction // incrPC
   
   
   function automatic void setcc(bit [15:0] val);
      if(val == 16'd0)
	N = 0; Z = 1; P = 0;
      else if (val[15] == 1'b1)
	N = 1; Z = 0; P = 0;
      else
	N = 0; Z = 0; P = 1;
   endfunction // setcc
      
   function automatic void LC3_ADD(Instruction I);
      
      if(I.instr[5]==0) begin
	 //Register Mode
	 RegFile[I.DR] = RegFile[I.SR1] + RegFile[I.SR2];
      end else begin
         //Immediate Mode
	 RegFile[I.DR] = RegFile[I.SR1] + Ext5.SEXT(I.imm5);
      end
	 
      setcc(RegFile[I.DR]);
	
   endfunction // LC3_ADD

   function automatic void LC3_AND(Instruction I);
       
      if(I.instr[5]==0) begin
	 //Register Mode
	 RegFile[I.DR] = RegFile[I.SR1] & RegFile[I.SR2];
      end else begin
         //Immediate Mode
	 RegFile[I.DR] = RegFile[I.SR1] & Ext5.SEXT(I.imm5);
      end
	 
      setcc(RegFile[I.DR]);
	
   endfunction // LC3_AND

   function automatic void LC3_BR(Instruction I);
      if((I.n && N) || (I.z && Z) || (I.p && P))
	PC = PC + Ext9.SEXT(I.PCoffset9);
   endfunction // LC3_BR
   
   function automatic void LC3_JMP(Instruction I);
      //This also covers RET
      PC = RegFile[I.BaseR];
   endfunction // LC3_JMP

   function automatic void LC3_JSR(Instruction I);
      RegFile[7] = PC;
      if(I.instr[11]=1)
	PC = I.BaseR;
      else
	PC = PC + Ext11.SEXT(I.PCoffset11);
      
   endfunction // LC3_JSR

   function automatic void LC3_LD(Instruction I, bit [15:0] mem_val);
      AddressQueue.push_back(PC + Ext9.SEXT(I.PCoffset9));
      RegFile[I.DR] = mem_val;
      setcc(mem_val);
   endfunction // LC3_LD

   function automatic void LC3_LDI(Instruction I, bit [15:0] mem_addr, bit mem_val);
      AddressQueue.push_back(PC+Ext9.SEXT(I.PCoffset9));
      AddressQueue.push_back(mem_addr);
      RegFile[I.DR] = mem_val;
      setcc(mem_val);
   endfunction // LC3_LDI

   function automatic void LC3_LDR(Instruction I, mem_val);
      AddressQueue.push_back(I.BaseR+Ext6.SEXT(I.offset6));
      RegFile[I.DR] = mem_val;
      setcc(mem_val);
   endfunction // LC3_LDR

   function automatic void LC3_LDR(Insturction I);
      RegFile[I.DR] = PC + Ext9.SEXT(I.PCoffset9);
      setcc(RegFile[I.DR]);
   endfunction // LC3_LDR

   function automatic void LC3_NOT(Instruction I);
      RegFile[I.DR] = ~RegFile[I.SR];
      setcc(RegFile[I.DR]);
   endfunction // LC3_NOT

   function automatic void LC3_ST(Instruction I);
      AddressQueue.push_back(PC + Ext9.SEXT(I.PCoffset9));
      DataQueue.push_back(RegFile[I.SR]);
   endfunction // LC3_ST

   function automatic void LC3_STI(Instruction I, bit [15:0] mem_addr);
      AddressQueue.push_back(PC + Ext9.SEXT(I.PCoffset9));
      AddressQueue.push_back(mem_addr);
      DataQueue.push_back(RegFile[I.SR]);
   endfunction // LC3_STI

   function automatic void LC3_STR(Instruction I);
      AddressQueue.push_back(I.BaseR + Ext6.SEXT(I.offset6));
      DataQueue.push_back(RegFile[I.SR]);
   endfunction // LC3_STR

   function automatic void LC3_TRAP(Instruction I, mem_addr);
      RegFile[7] = PC;
      AddressQueue.push_back(Ext8.ZEXT(I.trapvect8));
      PC = AddressQueue.push_back(mem_addr);
   endfunction // LC3_TRAP
         
   
      
   
endclass // Scoreboard
