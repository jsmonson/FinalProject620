`default_nettype none
module lc3_control ( clk, rst, 
                     IR, N, Z, P,  
                     aluControl, enaALU, SR1, SR2,
                     DR, regWE, selPC, enaMARM, selMAR,
		     selEAB1, selEAB2, enaPC, ldPC, ldIR,
	             ldMAR, ldMDR, selMDR, memWE, flagWE, enaMDR); 

input wire clk;
input wire rst;

input wire [15:0] IR;
input wire N;
input wire Z; 
input wire P; 

//Output
output reg [1:0] aluControl = 2'b00; 
output reg [2:0] SR1 = 3'b000;
output reg [2:0] SR2 = 3'b000;
output reg [2:0] DR = 3'b000;

output reg enaALU = 1'b0;
output reg enaPC = 1'b0;
output reg enaMDR = 1'b0;
output reg enaMARM = 1'b0;

output reg [1:0] selPC = 2'b00;
output reg selMAR = 1'b0;
output reg selEAB1 = 1'b0;
output reg [1:0] selEAB2 = 2'b00;
output reg selMDR = 1'b0;

output reg ldPC = 1'b0;
output reg ldIR = 1'b0;
output reg ldMAR = 1'b0;
output reg ldMDR = 1'b0;

output reg memWE = 1'b0;
output reg flagWE = 1'b0;
output reg regWE = 1'b0;


reg [4:0] CurrentState; 
reg [4:0] NextState; 
wire branch_enable; 

parameter FETCH0=5'd0, 
          FETCH1=5'd1, 
          FETCH2=5'd2, 
          DECODE=5'd3, 
          BRANCH0=5'd4, 
          ADD0=5'd5, 
          STORE0=5'd7, 
          STORE1=5'd8,
          STORE2=5'd9, 
          JSR0=5'd10, 
          JSR1=5'd11, 
          AND0=5'd12, 
          NOT0=5'd13, 
          JMP0=5'd14, 
          LD0=5'd15, 
          LD1=5'd16, 
          LD2=5'd17;

parameter BR=4'b0000, ADD=4'b0001, LD=4'b0010, ST=4'b0011,
          JSR=4'b0100, AND=4'b0101, LDR=4'b0110, STR=4'b0111,
          RTI=4'b1000, NOT=4'b1001, LDI=4'b1010, STI=4'b1011,
          JMP=4'b1100, RES=4'b1101, LEA=4'b1110, TRAP=4'b1111;


assign  branch_enable = ((N == IR[11]) || (Z == IR[10]) || (P == IR[9])) ? 1'b1 : 1'b0; 

always @ (posedge clk or posedge rst) begin
 if(rst)
  CurrentState <= FETCH0; 
 else  
  CurrentState <= NextState; 
end

always @ (CurrentState or IR or 
          N or Z or P or branch_enable) begin 
  //Tristate Signals
  enaALU <= 1'b0; enaMARM <= 1'b0;
  enaPC <= 1'b0; enaMDR <= 1'b0;

  //Register Load Signals  
  ldPC <= 1'b0; ldIR <= 1'b0;
  ldMAR <= 1'b0; ldMDR <= 1'b0;

  //MUX Select Signal
  selPC <= 2'b00; selMAR <= 1'b0;
  selEAB1 <= 1'b0; selEAB2 <= 2'b00;
  selMDR <= 1'b0; 

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
      NextState <= FETCH1;
      //Load PC ADDRESS
      enaPC <= 1'b1; ldMAR <= 1'b1; 
    end
    FETCH1: begin
      NextState <= FETCH2;
      //READ Instruction From Memory
      selMDR<=1'b1; ldMDR<=1'b1;
      //Incremente Program Counter
      selPC<=2'b00;
      ldPC<=1'b1;  
    end
    FETCH2: begin
      NextState <= DECODE;
      //Load Instruction Register
      enaMDR <= 1'b1; ldIR <= 1'b1;       
    end
    DECODE: begin 
      case (IR[15:12])  //AND, ADD, NOT, JSR, BR, LD, ST, JMP.
        BR:  NextState <= BRANCH0;//**//
        ADD: NextState <= ADD0;   //**//
        LD:  NextState <= LD0;  //**// 
        ST:  NextState <= STORE0; //**//
        JSR: NextState <= JSR0;   //**//
	JSRR: NextState <= JSRR0; //**//
	RET: NextState <= RET0;   //**//
        AND: NextState <= AND0;   //**//
        LDR: NextState <= LDR0; //**//
        STR: NextState <= STORE0; //**//
        RTI: NextState <= RTI0;  //**//
        NOT: NextState <= NOT0;   //**//
        LDI: NextState <= LD0;    //**//
        STI: NextState <= STORE1; //**// 
        JMP: NextState <= JMP0;   //**//
        RES: NextState <=  FETCH0; 
        LEA:  NextState <= LEA0;  //**//
        TRAP: NextState <= TRAP0; 
       endcase
    end 
    BRANCH0:  begin
     //Select ADDER inputs
     selEAB1 <= 1'b0; 
     selEAB2 <= 2'b10;
     //Load the New PC Value (if Branch Condition Met)
     ldPC <= branch_enable; 
     selPC <= 2'b01;
     NextState <= FETCH0;
    end
    RET0: begin
       SR1 <= 3'b111;
       selEAB1 <= 1'b1;
       selEAB2 <= 2'b00;
       selPC <= 1'b1;
       ldPC <= 1'b1;
       NextState <= FETCH0;       
    end
    
    RTI0: begin
      //Load the PC with the Stack Pointer
      SR1 <= 3'110;
      aluControl <= 2'b00;
      enaALU <= 1'b1;
      ldMAR <= 1'b1;
      NextState <= RTI1;
    end 
    
    RTI1: begin
       selMDR <= 1'b1;
       ldMDR <= 1'b1;
       NextState <= RTI2;
    end
    
    RTI2: begin
       enaMDR <= 1'b1;
       selPC <= 2'b10;
       ldPC <= 1'b1;
       NextState <= Fetch0;   
    end

    TRAP0: begin
       //Save the Current PC To R7
       enaPC <= 1'b1;
       DR <= 3'111;
       regWE <= 1'b1;
       NextState <= TRAP1;
    end

    TRAP1: begin
      //Write the Trap Vector the MAR
      selMAR <= 1'b1;
      enaMARM <= 1'b1;
      ldMAR <= 1'b1;
      NextState <= TRAP2;
    end
    
    TRAP2: begin
      //Load the MDR
      selMDR<= 1'b1;
      ldMAR <= 1'b1;
      NextState <= TRAP3;
    end

    TRAP3: begin
      //Load the PC
      enaMDR <= 1'b1;
      selPC <= 2'b10;
      ldPC <= 1'b1;
      NextState <= Fetch0;
    end
    
    STR1: begin
     selEAB1 <= 1'b1;
     selEAB2 <= 2'b01;
     selMAR <= 1'b0;
     enaMARM <= 1'b1;
     ldMAR <= 1'b1;
     
     NextState <= STORE2;
       
    end
    LD0: begin
     //Load MAR
     selEAB2 <= 2'b10; 
     selEAB1 <= 1'b0; 
     selMAR <= 1'b0; 
     enaMARM <= 1'b1; 
     ldMAR <= 1'b1;
     NextState <= LD1;
    end
    LD1: begin
     //Load MDR
     selMDR <= 1'b1; 
     ldMDR <= 1'b1;
     if( IR[15:12] == LDI )
       NextState <= LDI2;
     else
       NextState <= LD2;
    end   
    LD2: begin
     //Write to Register File 
     DR <= IR[11:9]; 
     regWE <= 1'b1; 
     enaMDR <= 1'b1; 
     NextState <= FETCH0;
    end
    LDI2: begin
       ldMAR <= 1'b1;
       enaMDR <= 1'b1;
       NextState <= LDI3;
    end
    LDI3: begin
       selMDR <= 1'b1;
       ldMDR <= 1'b1;
       NextState <= LD2;
    end
    LDR0: begin
       selEAB1 <= 1'b1;
       selEAB2 <= 2'b01;
       selMAR <= 1'b0;
       enaMARM <= 1'b1;
       ldMAR <= 1'b1;
       //The remaining is the same as the
       // the load insturctions
       NextState <= LD1;  
    LEA0: begin
       selEAB1 <= 1'b0;
       selEAB2 <= 2'b10;
       selMAR <= 1'b0;
       enaMARM <= 1'b1;
       DR <= IR[11:9];
       regWR <= 1'b1;
       NextState <= Fetch0;
    end
    
    NOT0: begin 
     aluControl <= 2'b11;
     enaALU <= 1'b1;
     SR1 <= IR[8:6]; 
     DR <= IR[11:9]; 
     regWE <= 1'b1;  
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
     NextState <= FETCH0;
    end
    AND0: begin 
     aluControl <= 2'b10;
     enaALU <= 1'b1;
     SR1 <= IR[8:6];
     SR2 <= IR[2:0];  
     DR <= IR[11:9]; 
     regWE <= 1'b1;  
     NextState <= FETCH0;
    end
    JSRR0: begin
       //Store the PC
       enaPC <= 1'b1;
       DR <= 3'111;
       regWE <= 1'b1;
       //Load PC From Register
       SR1 <= IR[8:6];
       selEAB1 <= 1'b1;
       selEAB2 <= 2'b00;
       selPC <= 2'b01;
       ldPC <= 1'b1;
       NextState <= FETCH0;
    STORE0: begin
     //Load the MDR 
     SR1 <= IR[11:9];
     aluControl <= 2'b00;
     enaALU <= 1'b1;
     selMDR <= 1'b0; 
     ldMDR <= 1'b1;
     if( IR[15:12] == STR )
       NextState <= STR1;
     else if ( IR[15:12] == STI )
       NextState <= STORE2;
     else
       NextState <= STORE1;
    end  
    STORE1: begin
     //Load the MAR 
     selEAB1 <= 1'b0; 
     selEAB2 <= 2'b10; 
     selMAR <= 1'b0; 
     enaMARM <= 1'b1; 
     ldMAR <= 1'b1;
     if( IR[15:12] == STR )
       NextState <= STI2;
     else
       NextState <= STORE2;
    end  
    STORE2: begin 
     memWE <= 1'b1; 
     NextState <= FETCH0;
    end
    STI2: begin
       selMDR <= 1'b1;
       lbMDR <= 1'b1;
       NextState <= STI3;
    end
    STI3: begin
       enaMDR <= 1'b1;
       ldMAR <= 1'b1;
       NextState <= STORE0;
    end   
    JSR0: begin 
     DR <= 3'b111; 
     enaPC <= 1'b1; 
     regWE <= 1'b1; 
     NextState <= JSR1;
   end  
   JSR1: begin 
     selEAB1 <= 1'b0; 
     selEAB2 <= 2'b11; 
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
  endcase
end  


endmodule
