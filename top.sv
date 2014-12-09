interface lc3_interface(input bit clk);
  logic [15:0] memory_dout, memory_addr, memory_din;
  logic memWE;
  bit rst;
  
  clocking cb @(posedge clk);
    input memory_addr, memory_din, memWE;
    output memory_dout;
  endclocking
  
  modport TEST(clocking cb, output rst);
  modport DUT(input clk, rst, memory_dout, output memory_addr, memory_din, memWE);
endinterface

module top;
  bit clk;
  always #10 clk = ~clk;
  
  lc3_interface lc3_if(clk);
  testbench tb(lc3_if.TEST);
  lc3 LC3 (lc3_if.DUT);
  
endmodule