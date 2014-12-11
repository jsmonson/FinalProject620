package EnvironmentPkg;

enum { BR, ADD, LD, ST,
       JSR, AND, LDR, STR,
       RTI, NOT, LDI, STI,
       JMP, RES, LEA, TRAP
     } Opcodes; 

  `define SV_RAND_CHECK(r)\
  do begin \
    if (!(r)) begin\
      $display("%s:%0d Randomization failed \"%s\"", \
          `__FILE__, `__LINE__, `"r`"); \
      end \
  end while(0) 
   
  int mem_access_cnt[Opcodes] = '{BR:1, ADD:1, LD:2, ST:2,
				  JSR:1, AND:1, LDR:2, STR:2,
				  RTI:2, NOT:1:, LDI:3, STI:3,
				  JMP:1, RES:1, LEA:1, TRAP:2};
`include "MemoryTransaction.sv"
`include "Scoreboard.sv"
`include "Generator.sv"
`include "Agent.sv"
`include "Driver.sv"
`include "Monitor.sv"
`include "Checker.sv"
`include "Environment.sv"

endpackage // EnvironmentPkg
   