class Test1 extends component;

   typedef registry #(Test1, "Test1") type_id;
   Environment Env;
   coverClass cl;
	class BadMemTr extends MemoryTransaction;
	   constraint d_out {
			(DataOut[15:12] == 4'b1000);
	   }
	   constraint c_mcr { 
			MCR[15] == 0;
	   }
	endclass

   virtual task run_test();
      $display("Running Basic Test");
      Env = new(1000, 20);	  
      Env.build();
	  cl = new();
	  fork
		begin
			BadMemTr bad = new();
			Env.gen.blueprint = bad;
		 Env.run();
		end
		cl.run();
		state_enum_run();
	  join_any

      $display("Test Finished");
      $stop;
   endtask // run_test
	task state_enum_run();// process to display ASCII instruction of processor
		forever begin
		  @$root.top.lc3_if.cb;
		  $cast(opcode_c,Env.drv.opcode);
		end
    endtask
endclass // Test0
