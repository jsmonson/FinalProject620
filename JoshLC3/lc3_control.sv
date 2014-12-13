`default_nettype none

import lc3Pkg::*;

module lc3_control ( clk, rst, 
                     IR, N, Z, P, PRIV, 
                     aluControl, enaALU, SR1, SR2,
                     DR, regWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
		     INT,
		     enaPSR, enaPCM1, enaSP, enaVector,
		     ldSavedUSP, ldSavedSSP, ldPriority, ldVector, ldCC, ldPriv,
		     selSPMUX, selPSRMUX, selVectorMUX, SetPriv,
	             ldMAR, ldMDR, selMDR, memWE, flagWE, enaMDR, memRDY); 

input wire clk;
input wire rst;

input wire [15:0] IR;
input wire N;
input wire Z; 
input wire P;
input logic PRIV;
input wire memRDY;
input logic INT;
   
//Output
output reg [1:0] aluControl = 2'b00; 
output reg [2:0] SR1 = 3'b000;
output reg [2:0] SR2 = 3'b000;
output reg [2:0] DR = 3'b000;

output reg enaALU = 1'b0;
output reg enaPC = 1'b0;
output reg enaMDR = 1'b0;
output reg enaMARM = 1'b0;
output logic enaPSR;
output logic enaPCM1;
output logic enaSP;
output logic enaVector;
   
output reg [1:0] selPC = 2'b00;
output reg selMAR = 1'b0;
output reg selEAB1 = 1'b0;
output reg [1:0] selEAB2 = 2'b00;
output reg selMDR = 1'b0;
output logic [1:0] selSPMUX;
output logic selPSRMUX;
output logic [1:0] selVectorMUX;
output logic SetPriv;
   
output reg ldPC = 1'b0;
output reg ldIR = 1'b0;
output reg ldMAR = 1'b0;
output reg ldMDR = 1'b0;
output logic ldSavedUSP;
output logic ldSavedSSP;
output logic ldPriority;
output logic ldVector;
output logic ldCC;
output logic ldPriv;

output reg memWE = 1'b0;
output reg flagWE = 1'b0;
output reg regWE = 1'b0;

ControlStates CurrentState; 
ControlStates NextState;
wire branch_enable; 

assign  branch_enable = ((N == IR[11]) || (Z == IR[10]) || (P == IR[9])) ? 1'b1 : 1'b0; 

always @ (posedge clk or posedge rst) begin
 if(rst)
  CurrentState <= FETCH0; 
 else  
  CurrentState <= NextState; 
end

always_comb begin 
  //Tristate Signals
  enaALU <= 1'b0; enaMARM <= 1'b0;
  enaPC <= 1'b0; enaMDR <= 1'b0;
  enaPSR <= 1'b0; enaPCM1 <= 1'b0;
  enaSP <= 1'b0; enaVector <= 1'b0;
   
  //Register Load Signals  
  ldPC <= 1'b0; ldIR <= 1'b0;
  ldMAR <= 1'b0; ldMDR <= 1'b0; 
  ldSavedUSP <= 1'b0; ldSavedSSP <= 1'b0;
  ldPriority <= 1'b0; ldVector <= 1'b0;
  ldCC <= 1'b0; ldPriv <= 1'b0;
   
  //MUX Select Signal
  selPC <= 2'b00; selMAR <= 1'b0;
  selEAB1 <= 1'b0; selEAB2 <= 2'b00;
  selMDR <= 1'b0; selVectorMUX <= 2'b00;
  selSPMUX <=2'b00; selPSRMUX <= 1'b0;
  selVectorMUX <= 2'b00; SetPriv <= 2'b00; 

  //Write Enable Signals 
  flagWE <= 1'b0; 
  memWE <= 1'b0;
  regWE <= 1'b0;  

  //Control Signals 
  aluControl <= 2'b00; 
  SR1 <= 3'b000;
  SR2 <= 3'b000;
  DR <= 3'b000;

  case (CurrentState)
    FETCH0: begin
      //MAR<-PC
      enaPC <= 1'b1; ldMAR <= 1'b1;
      //PC + 1
      selPC <=2'b00;
      ldPC<=1'b1;
      //Check for an Interrupt
      if(!INT)
	NextState <= FETCH1;
      else
	NextState <= INT0; 
     end
    
    FETCH1: begin
      if(memRDY) begin
        //MDR <- MEM[MAR]
        selMDR<=1'b1; ldMDR<=1'b1;
	NextState <= FETCH2;
      end      
    end
    
    FETCH2: begin
      NextState <= DECODE;
      //Load Instruction Register
      enaMDR <= 1'b1; ldIR <= 1'b1;       
    end
    
    DECODE: begin 
      case (IR[15:12])  //AND, ADD, NOT, JSR, BR, LD, ST, JMP.
        BR:  NextState <= BR0;//**//
        ADD: NextState <= ADD0;   //**//
        LD:  NextState <= LD0;  //**// 
        ST:  NextState <= ST0; //**//
        JSR: NextState <= JSR0;   //**//
        AND: NextState <= AND0;   //**//
        LDR: NextState <= LDR0; //**//
        STR: NextState <= STR0; //**//
        RTI: NextState <= RTI0;  //**//
        NOT: NextState <= NOT0;   //**//
        LDI: NextState <= LDI0;    //**//
        STI: NextState <= STI0; //**// 
        JMP: NextState <= JMP0;   //**//
        RES: NextState <=  FETCH0; 
        LEA:  NextState <= LEA0;  //**//
        TRAP: NextState <= TRAP0; //**//
       endcase
    end 
    BR0:  begin
     //Select ADDER inputs
     selEAB1 <= 1'b0; 
     selEAB2 <= 2'b10;
     //Load the New PC Value (if Branch Condition Met)
     ldPC <= branch_enable; 
     selPC <= 2'b01;
     NextState <= FETCH0;
    end
        
    RTI0: begin
      //MAR <- SP
      SR1 <= 3'b110;
      aluControl <= 2'b00;
      enaALU <= 1'b1;
      ldMAR <= 1'b1;
      if(PRIV)
	NextState <= RTI1;
      else
	NextState <= RTI2;
    end 
    
    RTI1: begin
       //RTI Priviledge Exception
       //Vector<-x00
       selVectorMUX <= 2'b01;
       ldVector <= 1'b1;
       //MDR<-PSR
       selMDR <= 1'b0;
       ldMDR <= 1'b1;
       enaPSR <= 1'b1;
       //PSR[15]<-0
       SetPriv <= 1'b0;
       ldPriv <= 1'b1;
       //Finish With Interrupt 
       NextState <= INT1;
    end
    
    RTI2: begin
       //MDR<-mem[MAR]
       selMDR <= 1'b1;
       if(memRDY) begin
	 ldMDR <= 1'b1;
	 NextState <= RTI3;
       end      
    end

    RTI3: begin
       //PC<-MDR
       enaMDR <= 1'b1;
       selPC <= 2'b10;
       ldPC <= 1'b1;
       NextState <= RTI4;
    end

    RTI4: begin
       //MAR,SP<-SP+1
       selSPMUX <= 2'b10;
       enaSP <= 1'b1;
       ldMAR <= 1'b1;
       DR <= 3'b110;
       regWE <= 1'b1;
       NextState <= RTI5;
    end

    RTI5: begin
       //MDR<-Mem[MAR]
       selMDR <= 1'b1;
       if(memRDY) begin
	 ldMDR <= 1'b1;
	 NextState <= RTI3;
       end     
    end
    
    RTI6: begin
       //PSR <-MDR
       enaMDR <= 1'b1;
       selPSRMUX <= 1'b0;
       ldPriv <= 1'b1;
       ldCC <= 1'b1;
       ldPriority <= 1'b1;
       NextState <= RTI7;
    end
    
    RTI7: begin
       selSPMUX <= 2'b10;
       enaSP <= 1'b1;
       DR <= 3'b110;
       regWE <= 1'b1;
       if(PRIV)
	 NextState <= RTI8;
       else
	 NextState <= RTI9;
    end

    RTI8: begin
       //SavedSSP <- SP
       ldSavedSSP <= 1'b1;
       SR1 <= 3'b110;
       //SP<-SavedUSP
       DR <= 3'b110;
       regWE <= 1'b1;
       selSPMUX <= 2'b11;
       NextState <= FETCH0;
    end

    RTI9: begin
       NextState <= FETCH0;
    end

    RES0: begin
        //RTI Priviledge Exception
       //Vector<-x00
       selVectorMUX <= 2'b01;
       ldVector <= 1'b1;
       //MDR<-PSR
       selMDR <= 1'b0;
       ldMDR <= 1'b1;
       enaPSR <= 1'b1;
       //PSR[15]<-0
       SetPriv <= 1'b0;
       ldPriv <= 1'b1;
       //Finish With Interrupt
       if(PRIV)  
	 NextState <= INT1;
       else
	 NextState <= INT2;
    end
    
    TRAP0: begin
       //MAR<-ZEXT(TRAPVECTOR8)
       selMAR <= 1'b1;
       enaMARM <= 1'b1;
       ldMAR <= 1'b1;
       NextState <= TRAP1;
    end
      
    TRAP1: begin
       if(memRDY) begin
	//R7 <- PC
        enaPC = 1'b1;
        DR = 3'b111;
        regWE = 1'b1;
	//MDR <- MEM[MAR]
	selMDR <= 1'b1;
	ldMDR <= 1'b1;
	NextState <= TRAP2;
       end  
    end
    
    TRAP2: begin
      //PC <- MDR
      enaMDR <= 1'b1;
      selPC <= 2'b10;
      ldPC <= 1'b1;
      NextState <= FETCH0;
    end
        
    LD0: begin
     // MAR <- PC + offset9
     selEAB2 <= 2'b10; 
     selEAB1 <= 1'b0; 
     selMAR <= 1'b0; 
     enaMARM <= 1'b1; 
     ldMAR <= 1'b1;
     NextState <= LD1;
    end

    LDI0: begin
       //MAR <-PC+off9
       selEAB1 <= 1'b0;
       selEAB2 <= 2'b10;
       selMAR <= 1'b0;
       enaMARM <= 1'b1;
       ldMAR <= 1'b1;
       NextState <= LDI1;
    end
    
    LDI1: begin
       //MDR<-Mem[MAR]
       if(memRDY) begin
	  selMDR <= 1'b1;
	  ldMDR <= 1'b1;
	  NextState <= LDI2;	  
       end
    end
    
    LDI2: begin
       //MDR<-MAR
       enaMDR <= 1'b1;
       ldMAR <= 1'b1;
       NextState <= LD1;
    end
    
    LD1: begin
     //MDR<-M[MAR]
     if(memRDY) begin
	selMDR <= 1'b1; 
	ldMDR <= 1'b1;
        NextState <= LD2;
     end
    end
   
    LD2: begin
     //DR <- MDR 
     DR <= IR[11:9]; 
     regWE <= 1'b1; 
     enaMDR <= 1'b1;
     ldCC<=1'b1;  
     NextState <= FETCH0;
    end
        
    LDR0: begin
       //MAR<-SR1+ offset6
       selEAB1 <= 1'b1;
       selEAB2 <= 2'b01;
       selMAR <= 1'b0;
       enaMARM <= 1'b1;
       ldMAR <= 1'b1;
       NextState <= LD1;
    end   
    LEA0: begin
       selEAB1 <= 1'b0;
       selEAB2 <= 2'b10;
       selMAR <= 1'b0;
       enaMARM <= 1'b1;
       DR <= IR[11:9];
       regWE <= 1'b1;
       ldCC <= 1'b1;
       NextState <= FETCH0;
    end
    
    NOT0: begin 
     aluControl <= 2'b11;
     enaALU <= 1'b1;
     SR1 <= IR[8:6]; 
     DR <= IR[11:9]; 
     regWE <= 1'b1;
     ldCC <= 1'b1;  
     NextState <= FETCH0;
    end 
    ADD0: begin 
     aluControl <= 2'b01;
     enaALU <= 1'b1;
     SR1 <= IR[8:6];
     SR2 <= IR[2:0];  
     DR <= IR[11:9]; 
     regWE <= 1'b1;  
     flagWE <= 1'b1;
     ldCC <= 1'b1;    
     NextState <= FETCH0;
    end
    AND0: begin 
     aluControl <= 2'b10;
     enaALU <= 1'b1;
     SR1 <= IR[8:6];
     SR2 <= IR[2:0];  
     DR <= IR[11:9]; 
     regWE <= 1'b1;
     ldCC <= 1'b1;
     NextState <= FETCH0;
    end
   
    STI0: begin
        //MAR <-PC+off9
       selEAB1 <= 1'b0;
       selEAB2 <= 2'b10;
       selMAR <= 1'b0;
       enaMARM <= 1'b1;
       ldMAR <= 1'b1;
       NextState <= STI1;
    end

    STI1: begin
       //MDR<-Mem[MAR]
       if(memRDY) begin
	  selMDR <= 1'b1;
	  ldMDR <= 1'b1;
	  NextState <= STI2;	  
       end
    end

    STI2: begin
      //MDR<-MAR
      enaMDR <= 1'b1;
      ldMAR <= 1'b1;
      NextState <= LD1;
    end

    STR0: begin
      //MAR<-SR1+ offset6
      selEAB1 <= 1'b1;
      selEAB2 <= 2'b01;
      selMAR <= 1'b0;
      enaMARM <= 1'b1;
      ldMAR <= 1'b1;
      NextState <= ST1;
    end
    
    ST0: begin
     //MAR <- PC + SEXT(offset9) 
     selEAB1 <= 1'b0; 
     selEAB2 <= 2'b10; 
     selMAR <= 1'b0; 
     enaMARM <= 1'b1; 
     ldMAR <= 1'b1;
     NextState <= ST1;  
    end
    
    ST1: begin
     //MDR<-SR
     SR1 <= IR[11:9];
     aluControl <= 2'b00;
     enaALU <= 1'b1;
     selMDR <= 1'b0; 
     ldMDR <= 1'b1;
     NextState <= ST2;  
    end

    ST2: begin
     //Mem[MAR] <- MDR
     if(memRDY) begin
       memWE <= 1'b1;
       selMDR <= 1'b1;
       NextState <= FETCH0;
     end
    end
        
   JSR0: begin
     //R7 <- PC
     DR <= 3'b111; 
     enaPC <= 1'b1; 
     regWE <= 1'b1;
     //Finish JSR or JSRR
     if(IR[11])
       NextState <= JSR1;
     else
       NextState <= JSR2;      
   end  
   JSR1: begin
     //PC <- PC + offset11
     selEAB1 <= 1'b0; 
     selEAB2 <= 2'b11; 
     selPC <= 2'b01; 
     ldPC <= 1'b1; 
     NextState <= FETCH0;
   end
 
   JSR2: begin
     //JSRR Instruction
     //PC <- SR1
     SR1 <= IR[8:6];
     selEAB1 <= 1'b1; 
     selEAB2 <= 2'b00; 
     selPC <= 2'b01; 
     ldPC <= 1'b1; 
     NextState <= FETCH0;
   end
   JMP0: begin 
     SR1 <= IR[8:6]; 
     selEAB1 <= 1'b1; 
     selEAB2 <= 2'b00; 
     selPC <= 2'b01; 
     ldPC <= 1'b1; 
     NextState <= FETCH0; 
   end
    
   INT0: begin
     //Vector <- INTV
     selVectorMUX <= 2'b00;
     ldVector <= 1'b1;
     //MDR <- PSR
     enaPSR <= 1'b1;
     selMDR <= 1'b0;
     ldMDR <= 1'b1;
     //PSR[10:8] <- Interrupt Priority
     selPSRMUX <= 1'b1;
     ldPriority <= 1'b1;
     //PSR[15] <- 0
     SetPriv <= 1'b0;

     if(PRIV)
       NextState <= INT1;
     else
       NextState <= INT2;      
   end // case: INT0
    
   INT1: begin
     //SavedUSP <- SP
     SR1 <= 3'b110;
     ldSavedUSP <= 1'b1;
     //SP <- Saved_SSP
     DR <= 3'b110;
     selSPMUX <= 2'b11;
     enaSP <= 1'b1;
     regWE <= 1'b1;
     NextState <= INT2; 
   end

   INT2: begin
     //MAR,SP<=SP-1
     SR1 <= 3'b110;
     DR <= 1'b1;
     selSPMUX <= 2'b01;
     enaSP <= 1'b1;
     regWE <= 1'b1;
     ldMAR <= 1'b1;
     NextState <= INT3;
   end

   INT3: begin
     if(memRDY) begin
	memWE <= 1'b1;
	NextState <= INT4;
     end
   end

   INT4: begin
     enaPCM1 <= 1'b1;
     ldMDR <= 1'b1;
     selMDR <= 1'b1;
     NextState <= INT5;
   end
        
   INT5: begin
     //MAR,SP<=SP-1
     SR1 <= 3'b110;
     DR <= 1'b1;
     selSPMUX <= 2'b01;
     enaSP <= 1'b1;
     regWE <= 1'b1;
     ldMAR <= 1'b1;
     NextState <= INT3;
   end

   INT6: begin
     if(memRDY) begin
       memWE <= 1'b1;
       NextState <= INT4;
     end
   end

   INT7: begin
     enaVector <= 1'b1;
     ldMAR <= 1'b1;
     NextState <= INT8; 
   end

   INT8: begin
     //MDR <- mem[MAR]
     if(memRDY) begin
       selMDR <= 1'b1;
       ldMDR <= 1'b1;
       NextState <= INT9;
     end
   end

   INT9: begin
      enaMDR <= 1'b1;
      selPC <= 2'b10;
      ldPC <= 1'b1;
      NextState<= FETCH0;
   end
        
  endcase
end  


endmodule
