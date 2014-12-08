
package lc3Pkg;
  typedef enum { FETCH0, FETCH1, FETCH2, 
         DECODE, 
         BRANCH0, 
         ADD0, 
         STORE0, STORE1, STORE2, 
         JSR0, JSR1,
	 LDR0,
	 LEA0,
	 TRAP0, TRAP1, TRAP2, TRAP3,
	 STR1,
	 LDI2, LDI3,
         AND0, 
         NOT0, 
         JMP0,
	 JSRR0,
	 RET0,
	 RTI0, RTI1, RTI2,
	 STI2, STI3,
         LD0, LD1, LD2} ControlStates; 
  enum { BR, ADD, LD, ST,
         JSR, AND, LDR, STR,
         RTI, NOT, LDI, STI,
         JMP, RES, LEA, TRAP,
	 JSRR, RET } Opcodes; 
endpackage