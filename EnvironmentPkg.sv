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
   
`include "MemoryTransaction.sv"
`include "Scoreboard.sv"
`include "Generator.sv"
`include "Agent.sv"
`include "Driver.sv"
`include "Monitor.sv"
`include "Checker.sv"
`include "Environment.sv"

endpackage // EnvironmentPkg
   