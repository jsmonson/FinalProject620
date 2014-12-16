import factory_pkg::*;
import EnvironmentPkg::*;

`include "Test0.sv"
 
program test;
	coverClass cl;
   initial begin
      component c;
      factory::printFactory();
      c = factory::get_test();
	  fork begin
		c.run_test();
		cl.run();
	  end join_any
   end
endprogram // test
 