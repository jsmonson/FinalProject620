   class Environment;
    //Virtual Interface to LC3
    vLC3if vlc3if;
       
    Generator gen;
    Agent agt;
    Driver drv;
    Monitor mon;
    Scoreboard scb;
    Checker chk;
 
    mailbox #(MemoryTransaction) gen2agt, agt2drv, agt2scb, scb2chk, mon2chk;
    int count;
    event agt2scbhs, chk2gen;
    function new(int count);
       this.count = count;
    endfunction;
    function void build();
      vlc3if = $root.top.lc3_if;
        
      gen2agt = new();
      agt2drv = new();
      agt2scb = new();
      scb2chk = new();
      mon2chk = new();
  
      gen = new(gen2agt, chk2gen);
      agt = new(gen2agt,agt2drv, agt2scb,agt2scbhs);
      drv = new(agt2drv, 3);
      mon = new(mon2chk, vlc3if);
      scb = new(agt2scb, scb2chk);
      chk = new(scb2chk, mon2chk, 
		chk2gen, scb);
       
    endfunction
  
    task run();
        fork
          gen.run(count);
          agt.run(count);
          drv.run(count);
	  mon.run(count);
	  scb.run(count);
          chk.run(count);
	   
        join
     endtask  
  endclass