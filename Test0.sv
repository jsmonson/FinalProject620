class Test0 extends component;

   typedef registry #(Test0, "Test0") type_id;
   Environment Env;
   coverClass cl;
   virtual task run_test();
      $display("Running Basic Test");	
      Env = new(10000, 20);
      Env.build();
	  cl = new();
	  fork
		Env.run();
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
