package AEnv;
  `define SV_RAND_CHECK(r)\
  do begin \
    if (!(r)) begin\
      $display("%s:%0d Randomization failed \"%s\"", \
          `__FILE__, `__LINE__, `"r`"); \
      end \
  end while(0) 
  `include "MemoryTransaction.sv"

 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction tr;
    event gen2agths;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event gen2agths);
        this.gen2agt = gen2agt;
        this.gen2agths = gen2agths;
    endfunction
    task run(input int count);
        repeat(count) begin
            tr = new();
            `SV_RAND_CHECK(tr.randomize());
            gen2agt.put(tr);
            wait (gen2agths.triggered);
        end
    endtask
  endclass
  
   class Agent;
      mailbox #(MemoryTransaction) gen2agt, agt2drv;
      MemoryTransaction tr;
      event gen2agths, agt2drvhs;
      function new(input mailbox #(MemoryTransaction) gen2agt, agt2drv, input event gen2agths,  agt2drvhs);
        this.gen2agt = gen2agt;
        this.agt2drv = agt2drv;
        this.gen2agths = gen2agths;
        this.agt2drvhs = agt2drvhs;
      endfunction
      task run(int count);
        repeat(count) begin
            gen2agt.get(tr);
            ->gen2agths;
            agt2drv.put(tr);
            wait (agt2drvhs.triggered);            
        end
      endtask
  endclass
  
  class Driver;
      mailbox #(MemoryTransaction) agt2drv;
      MemoryTransaction tr;
      event agt2drvhs; // mailbox synchronization
      function new(input mailbox #(MemoryTransaction) agt2drv, input event agt2drvhs);
        this.agt2drv = agt2drv;
        this.agt2drvhs = agt2drvhs;
	  endfunction
      task run(input int count);
		agt2drv.get(tr);
		->agt2drvhs; // tell agent that transaction has been driven onto DUT
		//$root.top.risc_if.data_out <= {4'hF,random_val()}; // random data with halt	 
		//@$root.top.risc_if.cb;	 
    endtask
  endclass
  // Will have to merge our environments...
   class Environment;
    Generator gen;
    Agent agt;
    Driver drv;
    mailbox #(MemoryTransaction) gen2agt, agt2drv;
    int count;
    event gen2agths, agt2drvhs;
    function new(int count);
       this.count = count;
    endfunction;
    function void build();
      gen2agt = new(1);
      agt2drv = new(1);
      gen = new(gen2agt,gen2agths);
      agt = new(gen2agt,agt2drv, gen2agths,agt2drvhs);
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
  
endpackage