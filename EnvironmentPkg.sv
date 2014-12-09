package EnvironmentPkg;

enum { BR, ADD, LD, ST,
       JSR, AND, LDR, STR,
       RTI, NOT, LDI, STI,
       JMP, RES, LEA, TRAP
     } Opcodes; 
   
`include "MemoryTransaction.sv"
`include "Scoreboard.sv"
    `define SV_RAND_CHECK(r)\
  do begin \
    if (!(r)) begin\
      $display("%s:%0d Randomization failed \"%s\"", \
          `__FILE__, `__LINE__, `"r`"); \
      end \
  end while(0) 
`include "Generator.sv"
`include "Agent.sv"
`include "Driver.sv"


  
   
  
  
  // Will have to merge our environments...
   class Environment;
    Generator gen;
    Agent agt;
    Driver drv;
    mailbox #(MemoryTransaction) gen2agt, agt2drv, agt2scb;
    int count;
    event gen2agths, agt2drvhs, agt2scbhs, chk2gen;
    function new(int count);
       this.count = count;
    endfunction;
    function void build();
      gen2agt = new(1);
      agt2drv = new(1);
	  agt2scb = new(1);
      gen = new(gen2agt,gen2agths, chk2gen);
      agt = new(gen2agt,agt2drv, agt2scb, gen2agths,agt2drvhs,agt2scbhs);
      drv = new(agt2drv,agt2drvhs);
    endfunction
  
    task run();
        fork
          gen.run(count);
          agt.run(count);
          drv.run(count);
        join
     endtask  
  endclass
endpackage // EnvironmentPkg
   