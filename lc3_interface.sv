interface lc3_interface(input bit clk);
   bit rst;
   bit [15:0] MCR;
     
   //Memory Signals
   bit [15:0] memory_dout;
   bit [15:0] memory_addr;
   bit [15:0] memory_din;
   bit 	      memWE;
   bit 	      memEN;
   bit 	      memRDY;
      
   //Memory Mapped I/O Signals
   bit [15:0] MemoryMappedIO_in;
   bit [15:0] MemoryMappedIO_out;
   bit 	      MemoryMappedIO_load;
   
   //External Interrupt Signals
   bit 	      IRQ;
   bit [7:0]  INTV;
   bit [2:0]  INTP;
  
   clocking cb @(posedge clk);
      output   rst, MCR;
      input   memory_addr, memory_din, memWE, memEN;
      output  memory_dout, memRDY;
      input   MemoryMappedIO_load, MemoryMappedIO_out;
      output  MemoryMappedIO_in;
      output  IRQ, INTV, INTP;
   endclocking
  
endinterface