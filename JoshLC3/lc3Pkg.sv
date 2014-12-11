
package lc3Pkg;
  typedef enum { FETCH0, FETCH1, FETCH2, 
         DECODE, 
         BR0, 
         ADD0, 
         ST0, ST1, ST2, 
         JSR0, JSR1, JSR2,
	 LDR0,
	 LEA0,
	 TRAP0, TRAP1, TRAP2, 
	 STR0, 
	 LDI0, LDI1, LDI2, 
         AND0, 
         NOT0, 
         JMP0,
	 RET0,
	 RTI0, RTI1, RTI2, RTI3, RTI4, RTI5, RTI6, RTI7, RTI8, RTI9,
	 RES0,
	 STI0, STI1, STI2,
         LD0, LD1, LD2,
	 INT0, INT1, INT2, INT3, INT4, INT5, INT6, INT7, INT8, INT9 } ControlStates; 
  enum { BR, ADD, LD, ST,
         JSR, AND, LDR, STR,
         RTI, NOT, LDI, STI,
         JMP, RES, LEA, TRAP,
	 JSRR, RET } Opcodes; 
endpackage