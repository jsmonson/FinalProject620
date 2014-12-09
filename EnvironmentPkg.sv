package EnvironmentPkg;

enum { BR, ADD, LD, ST,
       JSR, AND, LDR, STR,
       RTI, NOT, LDI, STI,
       JMP, RES, LEA, TRAP
     } Opcodes; 
   
`include "MemoryTransaction.sv"
`include "Scoreboard.sv"
   
endpackage // EnvironmentPkg
   