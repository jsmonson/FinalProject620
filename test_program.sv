import factory_pkg::*;
import EnvironmentPkg::*;

`include "Test0.sv"
`include "Test1.sv"
 
program test;

   initial begin
      component c;
      factory::printFactory();
      c = factory::get_test();
	  c.run_test();
   end
endprogram // test
 