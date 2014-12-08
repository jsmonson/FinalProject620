`default_nettype none
module lc3_datapath ( clk, rst, 
                     IR_OUT, N_OUT, Z_OUT, P_OUT,  
                     aluControl, enaALU, SR1, SR2,
                     DR, regWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, flagWE, enaMDR, 
                     memory_din, memory_dout, memory_addr); 
input wire clk;
input wire rst;

input wire [1:0] aluControl;
input wire enaALU;
input wire [2:0] SR1; 
input wire [2:0] SR2;
input wire [2:0] DR;
input wire regWE;
input wire [1:0] selPC;
input wire enaMARM;
input wire selMAR;
input wire selEAB1;
input wire [1:0] selEAB2;
input wire enaPC;
input wire ldPC;
input wire ldIR;
input wire ldMAR;
input wire ldMDR;
input wire selMDR;
input wire flagWE;
input wire enaMDR;

input wire [15:0] memory_dout;

output wire [15:0] IR_OUT; 
output wire N_OUT;
output wire Z_OUT;
output wire P_OUT;

output wire [15:0] memory_din;
output wire [15:0] memory_addr; 


//Datapath Registers 
reg [15:0] PC;
reg [15:0] IR;
reg [15:0] MAR;
reg [15:0] MDR;
reg N, Z, P;
reg [15:0] REGFILE [0:7];

//reg [15:0] MEMORY [0:255];

wire [15:0] BUSS;

//Multiplexors
reg [15:0] PCMUX; 
wire [15:0] MARMUX;
wire [15:0] MDRMUX;
wire [15:0] ADDR1MUX; 
reg [15:0] ADDR2MUX;
wire [15:0] SR2MUX;

//Arithmetic Units
wire [15:0] ADDER;
wire [15:0] PCINCR; 
reg [15:0] ALU;
wire [15:0] ZERO16;
reg [15:0] i; 
//Register File Outputs
wire [15:0] RA;
wire [15:0] RB; 

//IR Sign Extension
wire [15:0] SEXT4;
wire [15:0] SEXT5;
wire [15:0] SEXT8;
wire [15:0] SEXT10;
wire [15:0] ZEXT;

wire [15:0] memOut; 

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
always @ (posedge clk) begin 
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

always @ (selPC or PCINCR or ADDER or BUSS) 
  case(selPC)
    2'b00: PCMUX = PCINCR;   
    2'b01: PCMUX = ADDER; 
    2'b10: PCMUX = BUSS;
    default: $display("PCMUX ERROR: Illegal Select Signal "); 
  endcase


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

always @ (posedge clk or rst) begin
 if(rst) begin
   MAR <= 16'd0;
 end else if(ldMAR == 1'b1) begin
   MAR <= BUSS; 
 end 
end 
/************************************
 MDR 
************************************/

always @ (posedge clk or rst) begin
 if(rst) begin
   MDR <= 16'd0; 
 end else if(ldMDR == 1'b1) begin
   MDR <= MDRMUX; 
 end
end 

/************************************
 Instruction Register 
************************************/

always @ (posedge clk or rst) begin 
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

always @ (selEAB2 or ZERO16 or SEXT5 or SEXT8 or SEXT10)
  case (selEAB2)
    2'b00: ADDR2MUX = ZERO16;
    2'b01: ADDR2MUX = SEXT5;
    2'b10: ADDR2MUX = SEXT8; 
    2'b11: ADDR2MUX = SEXT10; 
  endcase 

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

always @ (aluControl, SR2MUX, RA)
  case(aluControl) 
    2'b00: ALU = RA;
    2'b01: ALU = RA + SR2MUX;
    2'b10: ALU = RA & SR2MUX;
    2'b11: ALU = ~RA; 
  endcase   

/************************************
 NZP Logic 
************************************/

always @ (posedge clk) begin
  if(BUSS[15] == 1'b1) begin
    N <= 1'b1; Z <= 1'b0; P <= 1'b0; 
  end else if(BUSS == 16'h0000) begin
    N <= 1'b0; Z <= 1'b1; P <= 1'b0; 
  end else begin
    N <= 1'b0; Z <= 1'b0; P <= 1'b1; 
  end
end 

/************************************
 Register File 
************************************/

always @ (posedge clk or posedge rst) begin
  if(rst) begin 
    for(i=0; i<16; i = i + 1) begin
      REGFILE[i] <= 16'd0;
    end 
  end else if(regWE) begin
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