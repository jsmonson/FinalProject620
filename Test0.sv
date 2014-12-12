class Test0 extends component;

   typedef registry #(Test0, "Test0") type_id;
   Environment Env;

   virtual task run_test();
      $display("Running Basic Test");

      Env = new(1000);
      Env.build();
      Env.run();

      $display("Test Finished");
      $stop;
   endtask // run_test

endclass // Test0
