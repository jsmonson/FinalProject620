class MemoryTransaction;
   time timestamp; //Monitor will fill in this value
   
   // ID members
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
   constraint c_mcr { MCR==16'h8000; };
   constraint c_rst { 
		rst dist {0:/70, 1:/30 };
	};
   constraint r_cyc { reset_cycles inside {[0:9]}; } 
   constraint c_irq {
		IRQ dist {0:/70, 1:/20 }; 
   };

 
   
   function MemoryTransaction copy(int i);
	  copy = new();
	  copy.timestamp = timestamp;
          copy.id = i;      
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
   function int ID();
      return id;
   endfunction    
      
   //Instruction Helper Functions   
   function bit [3:0] Opcode();
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[15:12];
      else
	return DataOut[15:12];
   endfunction // Opcode

   function bit [2:0] Imm();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[5];
      else
	return DataOut[5];
   endfunction // DR
   
   function bit [2:0] JSRR();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[11];
      else
	return DataOut[11];
   endfunction // DR
   
   function bit [2:0] DR();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[11:9];
      else
	return DataOut[11:9];
   endfunction // DR

   function bit [2:0] SR1();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[8:6];
      else
	return DataOut[8:6];
   endfunction // SR1

   function bit [2:0] SR2();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[2:0];
      else
	return DataOut[2:0];
   endfunction // SR2

   function bit [2:0] SR();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[11:9];
      else
	return DataOut[11:9];
   endfunction // SR

   function bit [2:0] BaseR();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[8:6];
      else
	return DataOut[8:6];
   endfunction // BaseR

   function bit [4:0] imm5();
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[4:0];
      else
	return DataOut[4:0];
   endfunction // imm5

   function bit [5:0] offset6();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[5:0];
      else
	return DataOut[5:0];
   endfunction // offset6

   function bit [7:0] trapvect8();
       if(Address>=16'hfe00)
	return MemoryMappedIO_in[7:0];
      else
	return DataOut[7:0];
   endfunction // trapvect8

   function bit [8:0] PCoffset9(); 
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[8:0];
      else
	return DataOut[8:0];
   endfunction // PCoffset9

   function bit [10:0] PCoffset11(); 
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[10:0];
      else
	return DataOut[10:0];    
   endfunction // PCoffset11
      
   function bit  n(); 
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[11];
      else
	return DataOut[11];
   endfunction // n

   function bit z(); 
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[10];
      else
	return DataOut[10];
   endfunction // z

   function bit p(); 
      if(Address>=16'hfe00)
	return MemoryMappedIO_in[9];
      else
	return DataOut[9];
   endfunction // p

endclass // MemoryTransaction

