
module top;
  bit clk;
  initial begin
	forever #10 clk = ~clk;
  end
  initial begin
	lc3_if.rst <= 1;
	#5;
	lc3_if.rst <= 0;
  end
  lc3_interface lc3_if(clk);
  test tb();
  lc3 LC3(.clk(clk),
	  .rst(lc3_if.rst),
	  .MCR(lc3_if.MCR),
	  .memory_dout(lc3_if.memory_dout),
	  .memory_addr(lc3_if.memory_addr),
	  .memory_din(lc3_if.memory_din),
	  .memWE(lc3_if.memWE),
	  .memEN(lc3_if.memEN),
	  .memRDY(lc3_if.memRDY),
	  .MemoryMappedIO_in(lc3_if.MemoryMappedIO_in),
	  .MemoryMappedIO_out(lc3_if.MemoryMappedIO_out),
	  .MemoryMappedIO_load(lc3_if.MemoryMappedIO_load),
	  .IRQ(lc3_if.IRQ),
	  .INTV(lc3_if.INTV),
	  .INTP(lc3_if.INTP));
  
endmodule // top
