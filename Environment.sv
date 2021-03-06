   class Environment;
    //Virtual Interface to LC3
    vLC3if vlc3if;
      int clock_period;
   
    Generator gen;
    Agent agt;
    Driver drv;
    Monitor mon; 
    Scoreboard scb;
    Checker chk;
	
    mailbox #(MemoryTransaction) gen2agt, agt2drv, agt2scb, scb2chk, mon2chk, drv2mon;
    int count;
    event agt2scbhs, chk2gen, drv2chk;
    function new(int count, int clock_periodi);
       this.count = count;
       clock_period=clock_periodi;
       
    endfunction;
    function void build();
      vlc3if = $root.top.lc3_if;
        
      gen2agt = new();
      agt2drv = new();
      agt2scb = new();
      scb2chk = new();
      mon2chk = new();
      drv2mon = new();
 
      gen = new(gen2agt, chk2gen);
      agt = new(gen2agt,agt2drv, agt2scb,agt2scbhs);
      drv = new(agt2drv, 3, vlc3if, chk2gen, drv2mon, drv2chk);
      mon = new(mon2chk, vlc3if, clock_period, drv2mon);
      scb = new(agt2scb, scb2chk, chk2gen);
      chk = new(scb2chk, mon2chk, 
		chk2gen, scb,drv2chk);
       
    endfunction
  
    task run();
        #(clock_period*6)
        fork
          gen.run(count);
          agt.run(count);
          drv.run(count);
		  mon.run(count);
	      scb.run(count);
          chk.run(count);
		  //cast_opcode(count);
		  
        join
     endtask  
	

  endclass