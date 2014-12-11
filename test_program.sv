import factory_pkg::*;

//Include Test Classes Here
 
program test;
   initial begin
      component c;
      
      factory::printFactory();
      c = factory::get_test();
      c.run_test();
   end
endprogram // test
 