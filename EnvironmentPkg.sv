package EnvironmentPkg;

typedef enum { tbBR=0, tbADD=1, tbLD=2, tbST=3,
       tbJSR=4, tbAND=5, tbLDR=6, tbSTR=7,
       tbRTI=8, tbNOT=9, tbLDI=10, tbSTI=11,
       tbJMP=12, tbRES=13, tbLEA=14, tbTRAP=15
     } tb_Opcodes; 
  	tb_Opcodes opcode_c;
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
`include "Covergroups.sv"


endpackage // EnvironmentPkg
   