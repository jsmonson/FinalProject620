`default_nettype none
module lc3(clk, 
           rst,
           memory_dout,
           memory_addr, 
           memory_din, 
          memWE);

input wire clk; 
input wire rst; 

input wire [15:0] memory_dout; 
 
output wire [15:0] memory_addr; 
output wire [15:0] memory_din;
output wire memWE;

wire [15:0] IR;
wire N; 
wire Z; 
wire P;  
wire [1:0] aluControl;
wire enaALU;
wire [2:0] SR1; 
wire [2:0] SR2;
wire [2:0] DR;
wire regWE;
wire [1:0] selPC;
wire enaMARM;
wire selMAR;
wire selEAB1;
wire [1:0] selEAB2;
wire enaPC;
wire ldPC;
wire ldIR;
wire ldMAR;
wire ldMDR;
wire selMDR;

wire flagWE;
wire enaMDR;

lc3_datapath DATAPATH( clk, rst, 
                     IR, N, Z, P,  
                     aluControl, enaALU, SR1, SR2,
                     DR, regWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, flagWE, enaMDR, 
                     memory_din, memory_dout, memory_addr);

lc3_control CONTROL( clk, rst, 
                     IR, N, Z, P,  
                     aluControl, enaALU, SR1, SR2,
                     DR, regWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, memWE, flagWE, enaMDR);  

endmodule