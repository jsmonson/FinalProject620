class Test0 extends component;

   typedef registry #(TestGood, "TestGood") type_id;
   Environment Env;

   virtual task run_test();
      $display("Running Basic Test");

      Env = new();
      Env.build();
      Env.run();

      $display("Test Finished");
      $stop;
   endtask // run_test

endclass // Test0
