   class Environment;
    Generator gen;
    Agent agt;
    Driver drv;
    mailbox #(MemoryTransaction) gen2agt, agt2drv, agt2scb;
	int mem_access_cnt[Opcodes] = '{BR:1, ADD:1, LD:2, ST:2,
									   JSR:1, AND:1, LDR:2, STR:2,
									   RTI:2, NOT:1:, LDI:3, STI:3,
									   JMP:1, RES:1, LEA:1, TRAP:2};
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