`default_nettype none
module lc3(clk, 
           rst,
           memory_dout,
           memory_addr, 
           memory_din, 
          memWE);

input logic clk; 
input logic rst; 

input logic [15:0] memory_dout; 
 
output logic [15:0] memory_addr; 
output logic [15:0] memory_din;
output logic memWE;

logic [15:0] IR;
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

lc3_datapath DATAPATH( clk, rst, 
                     IR, N, Z, P,  
                     aluControl, enaALU, SR1, SR2,
                     DR, logicWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, flagWE, enaMDR, 
                     memory_din, memory_dout, memory_addr);

lc3_control CONTROL( clk, rst, 
                     IR, N, Z, P,  
                     aluControl, enaALU, SR1, SR2,
                     DR, logicWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, memWE, flagWE, enaMDR);  

endmodule