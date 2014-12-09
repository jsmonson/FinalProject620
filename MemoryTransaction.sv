class MemoryTransaction;
   time timestamp;
      
   bit [15:0] Address;
   rand bit [15:0] DataOut;
   bit [15:0] DataIn;
   bit 	      we;
   bit 	      isInstr;

   //Instruction Helper Functions   
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
