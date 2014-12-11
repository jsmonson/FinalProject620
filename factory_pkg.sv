
package factory_pkg;
   
virtual class component;
   pure virtual task run_test();
endclass // component

virtual class wrapper;
   pure virtual function string get_type_name();
   pure virtual function component create_object(string name);
endclass // wrapper             

class factory;
   static wrapper type_names[string];
   static factory inst;

   static function factory get();
      if (inst == null) inst = new();
      return inst;
   endfunction // get

   static function register(wrapper c);
      type_names[c.get_type_name()] = c;
   endfunction // register

   static function component get_test();
      string name;
      wrapper test_wrapper;
      component test_component;
      if( !$value$plusargs("TESTNAME=%s",name))begin
	 $display("FATAL +TESTNAME not found");
	 $finish;
      end
      $display("%m found TESTNAME=%s",name);
      test_wrapper = factory::type_names[name];
      $cast(test_component, test_wrapper.create_object(name));
      return test_component;
   endfunction // get_test

   static function void printFactory();
      $display("Factory:");
      foreach (type_names[s]) $display("The name: %s maps to the class: %p", s, type_names[s]);
   endfunction // printFactory
endclass // factory

class registry #(type T, string Tname) extends wrapper;
   typedef registry #(T,Tname) this_type;
   local static this_type me = get();

   static function this_type get();
      if(me == null) begin
	 factory f = factory::get();
	 me = new();
	 void'(f.register(me));
      end
      return me;
   endfunction // get

   virtual function string get_type_name();
      return Tname;
   endfunction // get_type_name

   virtual function component create_object(string name);
      T toReturn;
      $display("Create_object called with %s which maps to key %s and class %s",
	       name,
	       Tname,
	       $typename(T));
      toReturn = new();
      return toReturn;   
   endfunction // create_object
endclass

endpackage // factory_pkg
