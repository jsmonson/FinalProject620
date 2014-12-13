class MemoryTransaction;
   time timestamp; //Monitor will fill in this value

   // ID members
   static int count = 0; // blueprint is -1
   int id;
   //This Bit is an Empty Transaction Generated by the Scoreboard to
   // tell the checker to compare the ScoreBoard State with 
   bit 	EndOfInstructionCycle;   

   bit [15:0] Address;
   rand bit [15:0] DataOut;
   bit [15:0] DataIn;
   bit 	      we;
   bit        en; //Distinguish between MIO Read and Memory Read	      
   bit 	      isInstr;
   
   //Reset Signal
   rand bit rst;
   
   //Interrupt Signal
   rand bit IRQ;
   rand bit [7:0] INTV;
   rand bit [2:0] INTP;
   rand int reset_cycles;   
   //Memory Mapped I/O Signals
   rand bit [15:0] MemoryMappedIO_in;
   bit 	      MemoryMappedIO_out;
   bit        MemoryMappedIO_load;

   //Machine Control Register
   rand bit [15:0] MCR;

   //Change these later... if necessary
   constraint c_mcr { MCR==0; };
   constraint c_rst { rst==0; };
   constraint r_cyc { reset_cycles == 1; }; 
   
   // generates unique ID value, assumes Generator is the only class who calls copy()
   function int genID();
	  return count++;
   endfunction
   
   function MemoryTransaction copy();
	  copy = new();
	  copy.id = genID();
	  copy.EndOfInstructionCycle = EndOfInstructionCycle;
	  copy.Address = Address;
	  copy.DataOut = DataOut;
	  copy.DataIn = DataIn;
	  copy.we = we;
	  copy.en = en;
	  copy.isInstr = isInstr;
	  copy.rst = rst;
	  copy.IRQ = IRQ;
	  copy.INTV = INTV;
	  copy.INTP = INTP;
	  copy.reset_cycles = reset_cycles;
	  copy.MemoryMappedIO_in = MemoryMappedIO_in;
	  copy.MemoryMappedIO_out = MemoryMappedIO_out;
	  copy.MemoryMappedIO_load = MemoryMappedIO_load;
	  copy.MCR = MCR;
   endfunction
   
   //Instruction Helper Functions  
   function bit [3:0] ID();
      return id;
   endfunction    
   
   function bit [3:0] Opcode();
      return DataOut[15:12];
   endfunction // Opcode

   function bit [2:0] DR();
      return DataOut[11:9];
   endfunction // DR

   function bit [2:0] SR1();
      return DataOut[8:6];
   endfunction // SR1

   function bit [2:0] SR2();
      return DataOut[2:0];
   endfunction // SR2

   function bit [2:0] SR();
      return DataOut[8:6];
   endfunction // SR

   function bit [2:0] BaseR();
      return DataOut[8:6];
   endfunction // BaseR

   function bit [4:0] imm5();
      return DataOut[4:0];
   endfunction // imm5

   function bit [5:0] offset6();
      return DataOut[5:0];
   endfunction // offset6

   function bit [7:0] trapvect8();
      return DataOut[7:0];
   endfunction // trapvect8

   function bit [8:0] PCoffset9();
      return DataOut[8:0];
   endfunction // PCoffset9

   function bit [10:0] PCoffset11();
      return DataOut[10:0];
   endfunction // PCoffset11
      
   function bit  n();
      return DataOut[11];
   endfunction // n

   function bit z();
      return DataOut[10];
   endfunction // z

   function bit p();
      return DataOut[9];
   endfunction // p

endclass // MemoryTransaction
