class Test0 extends component;

   typedef registry #(Test0, "Test0") type_id;
   Environment Env;
   coverClass cl;
   virtual task run_test();
      $display("Running Basic Test");	
      Env = new(10, 20);
      Env.build();
	  cl = new();
	  fork
		Env.run();
		cl.run();
	  join_any

      $display("Test Finished");
      $stop;
   endtask // run_test

endclass // Test0
