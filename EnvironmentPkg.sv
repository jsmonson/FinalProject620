package EnvironmentPkg;

enum { tbBR, tbADD, tbLD, tbST,
       tbJSR, tbAND, tbLDR, tbSTR,
       tbRTI, tbNOT, tbLDI, tbSTI,
       tbJMP, tbRES, tbLEA, tbTRAP
     } tb_Opcodes; 

  `define SV_RAND_CHECK(r)\
  do begin \
    if (!(r)) begin\
      $display("%s:%0d Randomization failed \"%s\"", \
          `__FILE__, `__LINE__, `"r`"); \
      end \
  end while(0) 

 typedef virtual lc3_interface vLC3if;
   
    
`include "MemoryTransaction.sv"
`include "Scoreboard.sv"
`include "Generator.sv"
`include "Agent.sv"
`include "Driver.sv"
`include "Monitor.sv"
`include "Checker.sv"
`include "Environment.sv"

endpackage // EnvironmentPkg
   