`default_nettype none
module lc3_datapath ( clk, rst, 
                     IR_OUT, N_OUT, Z_OUT, P_OUT, PRIV,  
                     aluControl, enaALU, SR1, SR2,
                     DR, logicWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, flagWE, enaMDR,
		     enaPSR, enaPCM1, enaSP, enaVector,
		     ldSavedUSP, ldSavedSSP, ldPriority, ldVector, ldCC, ldPriv,
		     selSPMUX, selPSRMUX, selVectorMUX, SetPriv,
		     IRQ, INTP, INTV, INT,
		     MemoryMappedIO_in, MemoryMappedIO_out, MemoryMappedIO_load, 
                     memory_din, memory_dout, memory_addr, memEN, memWEi, memWEo,
		      PSR_15); 
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

input logic  [15:0] MemoryMappedIO_in;
output logic [15:0] MemoryMappedIO_out;
output logic        MemoryMappedIO_load;
   
input logic [15:0] memory_dout;

output logic [15:0] IR_OUT; 
output logic N_OUT;
output logic Z_OUT;
output logic P_OUT;
output logic PRIV;
   
output logic [15:0] memory_din;
output logic [15:0] memory_addr; 
output logic memEN;
input logic memWEi;
output logic memWEo;
   
   
   
input logic 	    enaPSR;
input logic 	    enaPCM1;
input logic 	    enaSP;
input logic 	    enaVector;
   
input logic         ldSavedUSP;
input logic 	    ldSavedSSP;
input logic 	    ldPriority;
input logic 	    ldVector;
input logic 	    ldCC;
input logic 	    ldPriv;
    
input logic [1:0]   selSPMUX;
input logic 	    selPSRMUX;
input logic [1:0]   selVectorMUX;
input logic 	    SetPriv;

input logic 	    IRQ; //Interrupt Request
input logic [2:0]   INTP; //Interrupt Priority
input logic [7:0]   INTV; //Interrupt Vector
output logic        INT; //Inform Control of Interrupt
output logic     PSR_15;
//Datapath Registers 
logic [15:0] PC;
logic [15:0] IR;
logic [15:0] MAR;
logic [15:0] MDR;
logic [15:0] PSR;
logic [15:0] SavedUSP;
logic [15:0] SavedSSP;
logic [2:0] NZP; 
logic [2:0] INTP_reg;
logic [15:0] Vector;
   
logic N, Z, P;
logic [15:0] REGFILE [8];

//logic [15:0] MEMORY [0:255];

wire [15:0] BUSS;

//Multiplexors
logic [15:0] PCMUX; 
logic [15:0] MARMUX;
logic [15:0] MDRMUX;
logic [15:0] ADDR1MUX; 
logic [15:0] ADDR2MUX;
logic [15:0] SR2MUX;
logic [15:0] PSRMUX;
logic [15:0] SPMUX;
logic [15:0] VectorMUX;
logic [15:0] INMUX;
logic [1:0] selINMUX;
   
logic [15:0] PC_MINUS_1;

   
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
assign N_OUT = PSR[2]; 
assign Z_OUT = PSR[1];
assign P_OUT = PSR[0]; 

assign memOut = memory_dout; 
assign memory_din = MDR; 
assign memory_addr = MAR;
assign PSR_15 = PSR[15];
   
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
 Program Status Register 
************************************/

always_ff @ (posedge clk iff rst == 0 or posedge rst) begin
   if(rst == 1'b1) begin
      PSR <= 16'd0;
   end else begin
      if(ldCC)
	PSR[2:0] <= PSRMUX[2:0];
      if(ldPriority)
	PSR[10:8] <= PSRMUX[10:8];
      if(ldPriv)
	PSR[15] <= PSRMUX[15];     
   end
end


always_ff @ (posedge clk iff rst == 0 or posedge rst) begin
   if(rst == 1'b1) begin
      INTP_reg <= 3'b0;
   end else begin
      if(IRQ)
	INTP_reg <= INTP;
   end
end
   
assign INT = (INTP_reg > PSR[10:8]); 
assign PRIV = PSR[15];
   
/************************************
 Program Status Register MUX
************************************/   

always_comb begin
   if(selPSRMUX == 1'b1)
     PSRMUX = { SetPriv, {4{1'b0}}, INTP, {5{1'b0}}, NZP};
   else
     PSRMUX = { BUSS[15],  {4{1'b0}}, BUSS[10:8], {5{1'b0}}, BUSS[2:0]};
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
 Stack Pointer Registers & MUXES
************************************/
   
always_ff @ (posedge clk iff rst==0 or posedge rst) begin
   if(rst) begin
      SavedUSP <= 16'd0;
      SavedSSP <= 16'd0;
   end else begin
      if(ldSavedUSP)
	SavedUSP <= REGFILE[SR1];
      if(ldSavedSSP)
	SavedSSP <= REGFILE[SR1];   
   end
end
   
always_comb begin
   unique case (selSPMUX)
     2'b00: SPMUX = SavedSSP;
     2'b01: SPMUX = REGFILE[SR1] - 1;
     2'b10: SPMUX = REGFILE[SR1] + 1;
     2'b11: SPMUX = SavedUSP;
   endcase // unique case (selSPMUX)
end      

/************************************
 Vector MUX
************************************/
  
   always_comb begin
     unique case (selVectorMUX)
       2'b00: VectorMUX = { 8'h01,INTV};
       2'b01: VectorMUX = 16'h0100;
       2'b10: VectorMUX = 16'h0101;
       default: $display("Vector ERROR: Illegal Select Signal ");
     endcase // unique case (selVectorMUX)
  end

  always_ff @ (posedge clk iff rst==0 or posedge rst) begin
     if(rst) begin
	Vector <= 16'd0;
     end else if(ldVector) begin
	Vector <= VectorMUX;
     end
  end
      
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
 Address Control Logic
************************************/

assign MemoryMappedIO_out = MDR;
   
always_comb begin
  
   
  //Default is Memory Read
  memWEo = memWEi;
  memEN = 1'b0;
  selINMUX = 1'b0; 
  MemoryMappedIO_load = 1'b0;

  if(MAR < 16'hFE00) begin
    //Memory Read/Write
     memEN  = selMDR;
  end else if(MAR >= 16'hFE00 && selMDR == 1'b1) begin
      //MemoryMappedIO Read
     selINMUX = 1'b1;    
     if(memWEi == 1'b1) begin
       //MemoryMappedIO Write
       MemoryMappedIO_load = 1'b1;
     end
  end     
  
end
   
/************************************
 INMUX
************************************/
  
always_comb begin
   case (selINMUX)
     1'b0: INMUX = memOut;
     1'b1: INMUX = MemoryMappedIO_in;
   endcase // case (selINMUX)
end    
   
/************************************
 MDRMUX 
************************************/

assign MDRMUX = (selMDR) ? INMUX : BUSS; 

/************************************
 PC Minus 1 
************************************/

assign PC_MINUS_1 = PC - 1;
   
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

assign NZP = {N,Z,P};
  
always_comb  begin
  if(BUSS == 16'h0000) begin
    N <= 1'b0; Z <= 1'b1; P <= 1'b0; 
  end else if(BUSS[15] == 1'b1) begin
    N <= 1'b1; Z <= 1'b0; P <= 1'b0; 
  end else if( | BUSS[14:0] == 1'b1) begin
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
assign BUSS = (enaPSR) ? PSR : 16'hZZZZ;
assign BUSS = (enaPCM1) ? PC_MINUS_1 : 16'hZZZZ;
assign BUSS = (enaSP) ? SPMUX : 16'hZZZZ;
assign BUSS = (enaVector) ? Vector : 16'hZZZZ;


`define assert_clk(arg) \
	assert property (@(posedge clk) disable iff (!rst) arg)
`define assert_async_rst(arg) \
	assert property (@(posedge clk) arg)

ERROR_RESET_SHOULD_CAUSE_SIGNALS_TO_BE_0:
	`assert_async_rst(rst |-> (PSR == 0) && (MAR == 0) && (MDR == 0) && (IR == 0) && (Vector == 0) && 
	(SavedUSP == 0) && (SavedSSP == 0) && (INTP_reg == 0) && (PC == 0) &&
	(REGFILE[0] == 0) && (REGFILE[1] == 0) && (REGFILE[2] == 0) && (REGFILE[3] == 0) && (REGFILE[4] == 0) && 
	(REGFILE[5] == 0) && (REGFILE[6] == 0) && (REGFILE[7] == 0));
ERROR_MULTIPLE_ENABLE_SIGNALS_WENT_HIGH:
	`assert_clk((enaMARM + enaPC + enaPCM1 + enaALU + enaMDR + enaVector + enaSP + enaPSR) <= 1);
ERROR_MUX_SELECTS_SHOULD_NOT_HAVE_UNDEFINED_VALUES:
	`assert_clk((selVectorMUX != 3) && (selPC != 3));
ERROR_LOAD_SHOULD_HAVE_OCCURRED:
	`assert_clk((enaMARM || enaPC || enaPCM1 || enaALU || enaMDR || enaVector || enaSP || enaPSR) |-> 
	(ldPC || ldIR || ldMAR || ldMDR || ldSavedUSP || ldSavedSSP || ldPriority || ldVector || ldPriv || logicWE || flagWE));
ERROR_NOTHING_DRIVING_ONTO_BUSS:
	`assert_clk((ldPC || ldIR || ldMAR || ldMDR || ldSavedUSP || ldSavedSSP || ldPriority || ldVector || ldPriv || logicWE || flagWE) 
	|-> (enaMARM || enaPC || enaPCM1 || enaALU || enaMDR || enaVector || enaSP || enaPSR) );
ERROR_CONDITION_CODES_WERE_NOT_SET:
	`assert_clk(flagWE |-> ##1 (N || Z || P));
ERROR_INTERRUPT_PRIORITY_SHOULD_BE_HIGH_ENOUGH_TO_FIRE:
	`assert_clk((INTP_reg > PSR[10:8]) |-> INT);

endmodule