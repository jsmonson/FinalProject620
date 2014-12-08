`default_nettype none
module lc3_datapath ( clk, rst, 
                     IR_OUT, N_OUT, Z_OUT, P_OUT,  
                     aluControl, enaALU, SR1, SR2,
                     DR, logicWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, flagWE, enaMDR, 
                     memory_din, memory_dout, memory_addr); 
input logic clk;
input logic rst;

input logic [1:0] aluControl;
input logic enaALU;
input logic [2:0] SR1; 
input logic [2:0] SR2;
input logic [2:0] DR;
input logic logicWE;
input logic [1:0] selPC;
input logic enaMARM;
input logic selMAR;
input logic selEAB1;
input logic [1:0] selEAB2;
input logic enaPC;
input logic ldPC;
input logic ldIR;
input logic ldMAR;
input logic ldMDR;
input logic selMDR;
input logic flagWE;
input logic enaMDR;

input logic [15:0] memory_dout;

output logic [15:0] IR_OUT; 
output logic N_OUT;
output logic Z_OUT;
output logic P_OUT;

output logic [15:0] memory_din;
output logic [15:0] memory_addr; 


//Datapath Registers 
logic [15:0] PC;
logic [15:0] IR;
logic [15:0] MAR;
logic [15:0] MDR;
logic N, Z, P;
logic [15:0] REGFILE [0:7];

//logic [15:0] MEMORY [0:255];

wire [15:0] BUSS;

//Multiplexors
logic [15:0] PCMUX; 
logic [15:0] MARMUX;
logic [15:0] MDRMUX;
logic [15:0] ADDR1MUX; 
logic [15:0] ADDR2MUX;
logic [15:0] SR2MUX;

//Arithmetic Units
logic [15:0] ADDER;
logic [15:0] PCINCR; 
logic [15:0] ALU;
logic [15:0] ZERO16;
logic [15:0] i; 
//Register File Outputs
logic [15:0] RA;
logic [15:0] RB; 

//IR Sign Extension
logic [15:0] SEXT4;
logic [15:0] SEXT5;
logic [15:0] SEXT8;
logic [15:0] SEXT10;
logic [15:0] ZEXT;

logic [15:0] memOut; 

assign IR_OUT = IR; 
assign N_OUT = N; 
assign Z_OUT = Z;
assign P_OUT = P; 

assign memOut = memory_dout; 
assign memory_din = MDR; 
assign memory_addr = MAR;

/************************************
 Program Counter 
************************************/

always_ff @ (posedge clk iff rst == 0 or posedge rst) begin 
  if (rst == 1'b1) begin 
    PC <= 16'd0; 
  end else if(ldPC) begin
    PC = PCMUX; 
  end
end

/************************************
 Program Counter MUX 
************************************/

assign PCINCR = PC + 16'd1;

always_comb begin 
  unique case(selPC)
    2'b00: PCMUX = PCINCR;   
    2'b01: PCMUX = ADDER; 
    2'b10: PCMUX = BUSS;
    default: $display("PCMUX ERROR: Illegal Select Signal "); 
  endcase
end

/************************************
 Memory 
************************************/

//always @(posedge clk)
//begin
//  if (memWE)
//    MEMORY[MAR] <= MDR; 
//end 

//assign memOut = MEMORY[MAR]; 

/************************************
 MAR 
************************************/

always_ff @ (posedge clk iff rst==0 or posedge rst) begin
 if(rst) begin
   MAR <= 16'd0;
 end else if(ldMAR == 1'b1) begin
   MAR <= BUSS; 
 end 
end 
/************************************
 MDR 
************************************/

always_ff @ (posedge clk iff rst == 0 or posedge rst) begin
 if(rst) begin
   MDR <= 16'd0; 
 end else if(ldMDR == 1'b1) begin
   MDR <= MDRMUX; 
 end
end 

/************************************
 Instruction Register 
************************************/

always_ff @ (posedge clk iff rst == 0 or posedge rst) begin 
  if(rst) begin 
    IR <= 16'd0; 
  end else if(ldIR == 1'b1) begin
    IR <= BUSS; 
  end 
end 

/************************************
 Instruction Register Sign Extend 
************************************/

assign SEXT4 = { {11{IR[4]}}, IR[4:0] };
assign SEXT5 = { {10{IR[5]}}, IR[5:0] };
assign SEXT8 = { {7{IR[8]}}, IR[8:0] };
assign SEXT10 = { {5{IR[10]}}, IR[10:0] };
assign ZEXT =   { 8'b0, IR[7:0] };

/************************************
 MARMUX
************************************/

assign MARMUX = (selMAR) ? ZEXT : ADDER;

/************************************
 ADDER
************************************/

assign ADDER = ADDR2MUX + ADDR1MUX; 

/************************************
 ADDR1MUX 
************************************/

assign ADDR1MUX = (selEAB1) ? RA : PC; 

/************************************
 ADDR2MUX 
************************************/
assign ZERO16 = 16'h0000;

always_comb begin
  unique case (selEAB2)
    2'b00: ADDR2MUX = ZERO16;
    2'b01: ADDR2MUX = SEXT5;
    2'b10: ADDR2MUX = SEXT8; 
    2'b11: ADDR2MUX = SEXT10; 
  endcase 
end
/************************************
 SR2MUX 
************************************/

assign SR2MUX = (IR[5]) ? SEXT4 : RB; 

/************************************
 MDRMUX 
************************************/

assign MDRMUX = (selMDR) ? memOut : BUSS; 

/************************************
 ALU 
************************************/

always_comb 
  unique case(aluControl) 
    2'b00: ALU = RA;
    2'b01: ALU = RA + SR2MUX;
    2'b10: ALU = RA & SR2MUX;
    2'b11: ALU = ~RA; 
  endcase   

/************************************
 NZP Logic 
************************************/

always_ff @ (posedge clk) begin
  if(BUSS == 16'h0000) begin
    N <= 1'b0; Z <= 1'b1; P <= 1'b0; 
  end
  if(BUSS[15] == 1'b1) begin
    N <= 1'b1; Z <= 1'b0; P <= 1'b0; 
  end
  if( | BUSS[14:0] == 1'b1) begin
    N <= 1'b0; Z <= 1'b0; P <= 1'b1; 
  end
end 

/************************************
 Register File 
************************************/

always_ff @ (posedge clk iff rst == 0 or posedge rst) begin
  if(rst) begin 
    for(i=0; i<16; i = i + 1) begin
      REGFILE[i] <= 16'd0;
    end 
  end else if(logicWE) begin
    REGFILE[DR] <= BUSS;
  end 
end 
assign RA = REGFILE[SR1];
assign RB = REGFILE[SR2]; 
  
/************************************
 BUSS 
************************************/

assign BUSS = (enaMARM) ? MARMUX : 16'hZZZZ; 
assign BUSS = (enaPC) ? PC : 16'hZZZZ;
assign BUSS = (enaALU) ? ALU : 16'hZZZZ;
assign BUSS = (enaMDR) ? MDR : 16'hZZZZ;

endmodule