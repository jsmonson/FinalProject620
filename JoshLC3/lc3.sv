`default_nettype none
module lc3(clk, 
           rst,
	   MCR,
	   
	   //Memory Signals
           memory_dout,
           memory_addr, 
           memory_din, 
           memWE_out, //R.W in Diagram
	   memEN, //Distinguish between MIO and MEM
	   memRDY, // R signal... Tells when Memory Access is complete
	   
	   //Memory Mapped I/O Signals
	   MemoryMappedIO_in,
	   MemoryMappedIO_out,
	   MemoryMappedIO_load,
	   
	   //External Interrupt Signals
	   IRQ, //Interrupt Request
	   INTV, //Interrupt Vector
	   INTP //Interrupt Priority
 	   );

input logic clk; 
input logic rst; 
input logic [15:0] MCR;
 
input logic [15:0] memory_dout; 
 
output logic [15:0] memory_addr; 
output logic [15:0] memory_din;
output logic memWE_out;
output logic memEN;
input  logic memRDY;

input logic  [15:0] MemoryMappedIO_in;
output logic [15:0] MemoryMappedIO_out;
output logic        MemoryMappedIO_load;
  
input logic 	  IRQ;
input logic [7:0] INTV;
input logic [2:0] INTP;
    
logic 	  clki; //Internal Clock
   
logic [15:0] 	    IR;
logic N; 
logic Z; 
logic P;  
logic [1:0] aluControl;
logic enaALU;
logic [2:0] SR1; 
logic [2:0] SR2;
logic [2:0] DR;
logic logicWE;
logic [1:0] selPC;
logic enaMARM;
logic selMAR;
logic selEAB1;
logic [1:0] selEAB2;
logic enaPC;
logic ldPC;
logic ldIR;
logic ldMAR;
logic ldMDR;
logic selMDR;

logic flagWE;
logic enaMDR;
logic memWEi;

   
logic PRIV;
logic enaPSR;
logic enaPCM1;
logic enaSP;
logic enaVector;
logic ldSavedUSP;
logic ldSavedSSP;
logic ldPriority;
logic ldVector;
logic ldCC;
logic ldPriv;
logic SetPriv;
logic INT;
  
logic [1:0] selSPMUX;
logic selPSRMUX;
logic [1:0] selVectorMUX;
logic    PSR_15;
   

assign clki = MCR[15] & clk;
      
lc3_datapath DATAPATH(clki, rst, 
                     IR, N, Z, P, PRIV, 
                     aluControl, enaALU, SR1, SR2,
                     DR, logicWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, flagWE, enaMDR,
		     enaPSR, enaPCM1, enaSP, enaVector,
		     ldSavedUSP, ldSavedSSP, ldPriority, ldVector, ldCC, ldPriv,
		     selSPMUX, selPSRMUX, selVectorMUX, SetPriv,
		     IRQ, INTP, INTV, INT,
		     MemoryMappedIO_in, MemoryMappedIO_out, MemoryMappedIO_load,
                     memory_din, memory_dout, memory_addr, memEN, memWEi, memWE_out,
		     PSR_15);

lc3_control CONTROL( clki, rst, 
                     IR, N, Z, P, PRIV,  
                     aluControl, enaALU, SR1, SR2,
                     DR, logicWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
		     INT, 
		     enaPSR, enaPCM1, enaSP, enaVector,
		     ldSavedUSP, ldSavedSSP, ldPriority, ldVector, ldCC, ldPriv,
		     selSPMUX, selPSRMUX, selVectorMUX, SetPriv,
	             ldMAR, ldMDR, selMDR, memWEi, flagWE, enaMDR, memRDY);  

endmodule