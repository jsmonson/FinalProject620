
module top;
  bit clk;
  always #10 clk = ~clk;
  
  lc3_interface lc3_if(clk);
  test tb();
  lc3 LC3(.clk(clk),
	  .rst(lc3_if.cb.rst),
	  .MCR(lc3_if.cb.MCR),
	  .memory_dout(lc3_if.cb.memory_dout),
	  .memory_addr(lc3_if.cb.memory_addr),
	  .memory_din(lc3_if.cb.memory_din),
	  .memWE(lc3_if.cb.memWE),
	  .memEN(lc3_if.cb.memEN),
	  .memRDY(lc3_if.cb.memRDY),
	  .MemoryMappedIO_in(lc3_if.cb.MemoryMappedIO_in),
	  .MemoryMappedIO_out(lc3_if.cb.MemoryMappedIO_out),
	  .MemoryMappedIO_load(lc3_if.cb.MemoryMappedIO_load),
	  .IRQ(lc3_if.cb.IRQ),
	  .INTV(lc3_if.cb.INTV),
	  .INTP(lc3_if.cb.INTP));
  
endmodule // top
