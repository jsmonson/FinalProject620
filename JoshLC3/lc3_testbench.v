`default_nettype none
`timescale 1ns/100ps 
`define TBSTATE_FETCH 1'b0
`define TBSTATE_EXECUTE 1'b1
`define INSTRUCTIONS_TO_EXECUTE 16'd10000
module lc3_testbench (); 
  
  event found_error;
  event evaluate_executeUpdateStatus; 
  function [16:0] ValidateRegisterUpdate;  
   input [63:0] regName;
   input [15:0] currentValue, expectedValue;
   input update; 
   reg [16:0] ret; 
   begin 
     $display("Checking Register %s @ time: %d", regName, $time);
     if(update == 1'b0) begin
        $display("   Error: %s is not scheduled for Update!", regName);
        -> found_error; 
        ret = 1;  
     end else if(currentValue == expectedValue) begin
        //Register Update Correctly
        $display("   Success: %s was updated as expected", regName);
        ret = 0; 
     end else begin
        $display("   Error: %s was %d expected %d", regName, currentValue, expectedValue);
        ->found_error; 
        ret = 1;
     end
     ValidateRegisterUpdate = ret;   
   end
  endfunction
   
  function [2:0] calc_nzp;
    input reg [15:0] buss;
    reg [2:0] nzp;
    begin
       
      if(buss[15] == 1'b1) 
        nzp = 3'b100;
      else if (buss == 15'd0) 
        nzp = 3'b010;
      else
        nzp = 3'b001; 
      $display("CALC NZP: %d", nzp);
      calc_nzp = nzp;
    end
  endfunction 
  
  parameter BR=4'b0000, ADD=4'b0001, LD=4'b0010, ST=4'b0011,
          JSR=4'b0100, AND=4'b0101, LDR=4'b0110, STR=4'b0111,
          RTI=4'b1000, NOT=4'b1001, LDI=4'b1010, STI=4'b1011,
          JMP=4'b1100, RES=4'b1101, LEA=4'b1110, TRAP=4'b1111;

  reg [15:0] regNamePC = "PC";

  reg clk, rst; 
  
  reg [15:0] memory_dout;
  wire [15:0] memory_addr;
  wire [15:0] memory_din;
  wire memWE; 
  
  event start_fetch;
  event start_execute;  
  
  reg rst_done = 1'b0;
  reg tbState = `TBSTATE_FETCH; 

  reg [15:0] NEXT_MEMORY_OUTPUT;

  reg UPDATE_MAR = 1'b0; 
  reg [15:0] UPDATE_MAR_VALUE; 

  reg UPDATE_MDR = 1'b0; 
  reg [15:0] UPDATE_MDR_VALUE; 
  
  reg UPDATE_PC = 1'b0; 
  reg [15:0] UPDATE_PC_VALUE; 

  reg UPDATE_IR = 1'b0; 
  reg [15:0] UPDATE_IR_VALUE;
  
  reg UPDATE_MEMORY = 1'b0; 
  reg [15:0] UPDATE_MEMORY_VALUE;
  
  reg UPDATE_NZP = 1'b0; 
  reg [15:0] UPDATE_NZP_VALUE;
  
  reg [15:0] InstrCount [15:0]; 
  reg [15:0] i;   

  reg UPDATE_REG0 = 1'b0; 
  reg UPDATE_REG1 = 1'b0; 
  reg UPDATE_REG2 = 1'b0; 
  reg UPDATE_REG3 = 1'b0; 
  reg UPDATE_REG4 = 1'b0; 
  reg UPDATE_REG5 = 1'b0; 
  reg UPDATE_REG6 = 1'b0; 
  reg UPDATE_REG7 = 1'b0; 

  reg [15:0] UPDATE_REG0_VALUE; 
  reg [15:0] UPDATE_REG1_VALUE; 
  reg [15:0] UPDATE_REG2_VALUE; 
  reg [15:0] UPDATE_REG3_VALUE;
  reg [15:0] UPDATE_REG4_VALUE; 
  reg [15:0] UPDATE_REG5_VALUE; 
  reg [15:0] UPDATE_REG6_VALUE; 
  reg [15:0] UPDATE_REG7_VALUE;
 
  wire [3:0] fetchUpdateStatus;
  wire [11:0] executeUpdateStatus;
  reg [11:0] executeUpdateStatus_i;
  reg [15:0] instructionCount; 
  
  reg [15:0] SEXT10, SEXT8, SEXT4, STOREVAL;
  reg [15:0] ADDER;
  reg [15:0] OP1, OP2; 
  reg [2:0] DST, SRC, SRC1, SRC2;
  reg [2:0] DSTREG; 
  reg [15:0] NZPTMP; 
  task setDstRegUpdate; 
    input [2:0] dst;
    input [15:0] val;   
    begin
      $display("Setting Reg %d with value %d for expected update", dst, val); 
      case (dst)
        3'd0: begin
          UPDATE_REG0 = 1'b1; 
          UPDATE_REG0_VALUE = val; 
        end
        3'd1: begin
          UPDATE_REG1 = 1'b1; 
          UPDATE_REG1_VALUE = val; 
        end 
        3'd2: begin
          UPDATE_REG2 = 1'b1; 
          UPDATE_REG2_VALUE = val; 
        end 
        3'd3: begin
          UPDATE_REG3 = 1'b1; 
          UPDATE_REG3_VALUE = val; 
        end 
        3'd4: begin
          UPDATE_REG4 = 1'b1; 
          UPDATE_REG4_VALUE = val; 
        end 
        3'd5: begin
          UPDATE_REG5 = 1'b1; 
          UPDATE_REG5_VALUE = val; 
        end 
        3'd6: begin
          UPDATE_REG6 = 1'b1; 
          UPDATE_REG6_VALUE = val; 
        end 
        3'd7: begin
          UPDATE_REG7 = 1'b1; 
          UPDATE_REG7_VALUE = val; 
        end  
      endcase
    end 
  endtask
  
  assign fetchUpdateStatus = { UPDATE_MAR, UPDATE_MDR, UPDATE_PC, UPDATE_IR };
  assign executeUpdateStatus = { UPDATE_MAR, UPDATE_MDR, UPDATE_PC, UPDATE_MEMORY, 
                                 UPDATE_REG0, UPDATE_REG1, UPDATE_REG2, UPDATE_REG3,
                                 UPDATE_REG4, UPDATE_REG5, UPDATE_REG6, UPDATE_REG7 };
  always begin
    #10 clk = !clk; 
  end 
  
  initial begin 
    clk = 0; 
    rst = 0;
    for (i=0; i<16; i = i + 1) begin 
      InstrCount[i] = 16'd0; 
    end
    instructionCount = 0; 
    NEXT_MEMORY_OUTPUT = 16'd0;
    @ (negedge clk)
    rst = 1; 
    @ (negedge clk)
    @ (negedge clk)
    @ (negedge clk)
    rst = 0; 
    rst_done = 1'b1;
    ->start_fetch; 
  end 
 
  initial begin 
    @ (found_error)
    $display("Simulation Terminated Due to Error");
    $finish(); 
  end
  initial begin
    forever begin
      @ (start_fetch)
      tbState <= `TBSTATE_FETCH;
      $display("****Starting Fetch of Instr: %d @ time ****", instructionCount, $time);
      //Schdule Register Updates
      UPDATE_MAR = 1'b1;  
      UPDATE_MAR_VALUE = LC3.DATAPATH.PC;
      UPDATE_PC = 1'b1;
      UPDATE_PC_VALUE = LC3.DATAPATH.PC + 1;
      UPDATE_IR = 1'b1;
      UPDATE_IR_VALUE = $random; 
      //$display("FET:IR_VALUE: %d", UPDATE_IR_VALUE);   
      NEXT_MEMORY_OUTPUT = UPDATE_IR_VALUE;
      //$display("FET:NEXT_MEM: %d", NEXT_MEMORY_OUTPUT);   
      UPDATE_MDR = 1'b1;
      UPDATE_MDR_VALUE = NEXT_MEMORY_OUTPUT; 
    end 
  end

  initial begin
    forever begin
      @ (start_execute);
      tbState = `TBSTATE_EXECUTE;
      $display("****Starting Execution of Instr: %d @ time: %d ****", instructionCount, $time); 
      DST = UPDATE_IR_VALUE[11:9];
      SRC = UPDATE_IR_VALUE[11:9];
      SRC1 = UPDATE_IR_VALUE[8:6];
      SRC2 = UPDATE_IR_VALUE[2:0];
      SEXT4 = { {11{UPDATE_IR_VALUE[4]}}, UPDATE_IR_VALUE[4:0] };
      SEXT8 = { {7{UPDATE_IR_VALUE[8]}}, UPDATE_IR_VALUE[8:0] };
      SEXT10 = { {5{UPDATE_IR_VALUE[10]}}, UPDATE_IR_VALUE[10:0] };
      STOREVAL = LC3.DATAPATH.REGFILE[SRC];
      OP1 =  LC3.DATAPATH.REGFILE[SRC1];
      OP2 =  LC3.DATAPATH.REGFILE[SRC2];
      InstrCount[UPDATE_IR_VALUE[15:12]] = InstrCount[UPDATE_IR_VALUE[15:12]] + 1;      
      //Schedule any Register Updates
      $display("OPCODE: %d", UPDATE_IR_VALUE); 
      case (UPDATE_IR_VALUE[15:12])  //AND, ADD, NOT, JSR, BR, LD, ST, JMP.
        BR: begin //**//
         $display(" Instr %d: BR", instructionCount); 
         if(UPDATE_IR_VALUE[11] == LC3.DATAPATH.N ||
            UPDATE_IR_VALUE[10] == LC3.DATAPATH.Z ||
            UPDATE_IR_VALUE[9]  == LC3.DATAPATH.P) begin 
            //Update Program Counter
            UPDATE_PC = 1'b1;
            UPDATE_PC_VALUE = UPDATE_PC_VALUE + SEXT8; 
         end  
        end
        ADD: begin    //**//
           $display(" Instr %d: ADD", instructionCount);
           if(UPDATE_IR_VALUE[5] == 1'b1) begin
             OP2 = SEXT4;  
           end 
           ADDER = OP1 + OP2; 
           setDstRegUpdate(DST, ADDER);
           UPDATE_NZP = 1'b1; 
           UPDATE_NZP_VALUE = { 12'd0, calc_nzp(ADDER)}; 
           $display("UPDATE_NZP: %d", UPDATE_NZP_VALUE);
        end 
        LD: begin //**// 
          $display(" Instr %d: LD", instructionCount);
          UPDATE_MAR = 1'b1;
          UPDATE_MAR_VALUE = UPDATE_PC_VALUE + SEXT8;
          UPDATE_MDR = 1'b1; 
          NEXT_MEMORY_OUTPUT = $random; 
          UPDATE_MDR_VALUE =  NEXT_MEMORY_OUTPUT; 
          setDstRegUpdate(DST, UPDATE_MDR_VALUE); 
          UPDATE_NZP = 1'b1; 
          UPDATE_NZP_VALUE = { 12'd0, calc_nzp(NEXT_MEMORY_OUTPUT)};
        end
        ST:  begin //**//
          $display(" Instr %d: ST SRC: %d ", instructionCount, SRC);
          UPDATE_MAR = 1'b1;
          UPDATE_MAR_VALUE = UPDATE_PC_VALUE + SEXT8;
          UPDATE_MDR = 1'b1;
          UPDATE_MDR_VALUE = STOREVAL; 
          UPDATE_MEMORY = 1'b1; 
          UPDATE_MEMORY_VALUE = STOREVAL; 
        end 
        JSR: begin   //**//
          $display(" Instr %d: JSR", instructionCount);
          setDstRegUpdate(3'd7, UPDATE_PC_VALUE); 
          UPDATE_PC = 1'b1; 
          UPDATE_PC_VALUE = UPDATE_PC_VALUE + SEXT10; 
        end
        AND: begin    //**//
          $display(" Instr %d: AND DST: %d SRC1: %d SRC2: %d", instructionCount, DST, SRC1, SRC2);
           if(UPDATE_IR_VALUE[5] == 1'b1) begin
             $display(" Instr %d: AND DST: %d SRC1: %d IMMED: %d", instructionCount, DST, SRC1, SEXT4);
             OP2 = SEXT4;  
           end 
           ADDER = OP1 & OP2; 
           setDstRegUpdate(DST, ADDER);            
           UPDATE_NZP = 1'b1; 
           UPDATE_NZP_VALUE = { 12'd0, calc_nzp(ADDER)};
        end 
        LDR: $display(" Instr %d: LDR", instructionCount);
        STR: $display(" Instr %d: STR", instructionCount);
        RTI: $display(" Instr %d: RTI", instructionCount);
        NOT: begin  //**//
           $display(" Instr %d: NOT", instructionCount);
           ADDER = ~OP1;
           setDstRegUpdate(DST, ADDER);            
           UPDATE_NZP = 1'b1; 
           UPDATE_NZP_VALUE = { 12'd0, calc_nzp(ADDER)};
        end  
        LDI:  $display(" Instr %d: LDI", instructionCount);
        STI:  $display(" Instr %d: STI", instructionCount);
        JMP:  begin //
          $display(" Instr %d: JMP BASE: %d", instructionCount, SRC1);
          UPDATE_PC = 1'b1; 
          UPDATE_PC_VALUE = OP1; 
        end 
        RES:  $display(" Instr %d: RES", instructionCount);
        LEA:  $display(" Instr %d: LEA", instructionCount);
        TRAP:  $display(" Instr %d: TRAP", instructionCount);
       endcase
       
       executeUpdateStatus_i = { UPDATE_MAR, UPDATE_MDR, UPDATE_PC, UPDATE_MEMORY, 
                                 UPDATE_REG0, UPDATE_REG1, UPDATE_REG2, UPDATE_REG3,
                                 UPDATE_REG4, UPDATE_REG5, UPDATE_REG6, UPDATE_REG7 };
       $display("executeUpdateState_i: %d", executeUpdateStatus_i);
       if(executeUpdateStatus_i == 12'd0) begin 
         $display("0:Execution of Instr %d Complete @ time: %d", instructionCount, $time);
         instructionCount = instructionCount + 1;
         -> start_fetch; 
       end
    end 
  end
  
  //Are we done with FETCH? 
  always @ (fetchUpdateStatus) begin
     //$display("fetchUpdateStatus: %x", fetchUpdateStatus);
     if ( fetchUpdateStatus == 4'b0000 && tbState == `TBSTATE_FETCH && rst_done) begin
       $display("Fetch of Instr %d Complete", instructionCount);
       -> start_execute; 
     end 
  end   

  //Are we done with FETCH? 
  always @ (executeUpdateStatus) begin
     //$display("executeUpdateStatus: %x", executeUpdateStatus);
     if ( executeUpdateStatus == 12'd0 && tbState == `TBSTATE_EXECUTE && rst_done) begin
       $display("1: Execution of Instr %d Complete", instructionCount);
       instructionCount = instructionCount + 1;
       -> start_fetch; 
     end 
  end

  /****************************************/
  /*  Processes to Monitor State Changes  */
  /****************************************/

  always @ (negedge LC3.DATAPATH.ldPC) begin
   if(rst == 1'b0 && rst_done) begin
    UPDATE_PC <= ValidateRegisterUpdate("PC", LC3.DATAPATH.PC, UPDATE_PC_VALUE, UPDATE_PC);
   end   
  end 
  
  always @ (negedge LC3.DATAPATH.ldMAR) begin
   if(rst == 1'b0 && rst_done) begin
    UPDATE_MAR <= ValidateRegisterUpdate("MAR", LC3.DATAPATH.MAR, UPDATE_MAR_VALUE, UPDATE_MAR);
   end   
  end

  always @ (negedge LC3.DATAPATH.ldMDR) begin
   if(rst == 1'b0 && rst_done) begin
    UPDATE_MDR <= ValidateRegisterUpdate("MDR", LC3.DATAPATH.MDR, UPDATE_MDR_VALUE, UPDATE_MDR);
   end   
  end

  always @ (negedge LC3.DATAPATH.ldIR) begin
   if(rst == 1'b0 && rst_done) begin
    UPDATE_IR <= ValidateRegisterUpdate("IR", LC3.DATAPATH.IR, UPDATE_IR_VALUE, UPDATE_IR);
   end   
  end   
  
  always @ (negedge LC3.DATAPATH.flagWE) begin
   if(rst == 1'b0 && rst_done) begin
    NZPTMP = { 12'd0, LC3.DATAPATH.N, LC3.DATAPATH.Z, LC3.DATAPATH.P};
    UPDATE_NZP <= ValidateRegisterUpdate("NZP", NZPTMP, UPDATE_NZP_VALUE, UPDATE_NZP);
   end   
  end  
  
  always @ (posedge LC3.DATAPATH.regWE) begin
   DSTREG = LC3.DATAPATH.DR;
   @ ( negedge LC3.DATAPATH.regWE )
   if(rst == 1'b0 && rst_done ) begin
    case (DSTREG) 
      3'd0: UPDATE_REG0 <= ValidateRegisterUpdate("REG0", LC3.DATAPATH.REGFILE[0], UPDATE_REG0_VALUE, UPDATE_REG0);
      3'd1: UPDATE_REG1 <= ValidateRegisterUpdate("REG1", LC3.DATAPATH.REGFILE[1], UPDATE_REG1_VALUE, UPDATE_REG1);
      3'd2: UPDATE_REG2 <= ValidateRegisterUpdate("REG2", LC3.DATAPATH.REGFILE[2], UPDATE_REG2_VALUE, UPDATE_REG2);
      3'd3: UPDATE_REG3 <= ValidateRegisterUpdate("REG3", LC3.DATAPATH.REGFILE[3], UPDATE_REG3_VALUE, UPDATE_REG3);
      3'd4: UPDATE_REG4 <= ValidateRegisterUpdate("REG4", LC3.DATAPATH.REGFILE[4], UPDATE_REG4_VALUE, UPDATE_REG4);
      3'd5: UPDATE_REG5 <= ValidateRegisterUpdate("REG5", LC3.DATAPATH.REGFILE[5], UPDATE_REG5_VALUE, UPDATE_REG5);
      3'd6: UPDATE_REG6 <= ValidateRegisterUpdate("REG6", LC3.DATAPATH.REGFILE[6], UPDATE_REG6_VALUE, UPDATE_REG6);
      3'd7: UPDATE_REG7 <= ValidateRegisterUpdate("REG7", LC3.DATAPATH.REGFILE[7], UPDATE_REG7_VALUE, UPDATE_REG7);
    endcase
   end   
  end 
   
  always @ (negedge LC3.DATAPATH.ldMAR) begin
    memory_dout <= NEXT_MEMORY_OUTPUT;
  end 
  
  always @ (negedge memWE) begin
     if(rst == 1'b0 && rst_done) begin
    UPDATE_MEMORY <= ValidateRegisterUpdate("MEMORY", memory_din, UPDATE_MEMORY_VALUE, UPDATE_MEMORY);
   end   
  end  

  always @ (instructionCount) begin 
    if (instructionCount >= `INSTRUCTIONS_TO_EXECUTE) begin
      $display("Test Vectors Complete! Executed %d instructions!", instructionCount); 
      //parameter BR=4'b0000, ADD=4'b0001, LD=4'b0010, ST=4'b0011,
      //    JSR=4'b0100, AND=4'b0101, LDR=4'b0110, STR=4'b0111,
      //    RTI=4'b1000, NOT=4'b1001, LDI=4'b1010, STI=4'b1011,
      //    JMP=4'b1100, RES=4'b1101, LEA=4'b1110, TRAP=4'b1111;
      $display("BR: %d", InstrCount[BR]);
      $display("ADD: %d", InstrCount[ADD]);
      $display("LD: %d", InstrCount[LD]);
      $display("ST: %d", InstrCount[ST]);
      $display("JSR: %d", InstrCount[JSR]);
      $display("AND: %d", InstrCount[AND]);
      $display("LDR: %d", InstrCount[LDR]);
      $display("STR: %d", InstrCount[STR]);
      $display("RTI: %d", InstrCount[RTI]);
      $display("NOT: %d", InstrCount[NOT]);
      $display("LDI: %d", InstrCount[LDI]);
      $display("STI: %d", InstrCount[STI]);
      $display("JMP: %d", InstrCount[JMP]);
      $display("RES: %d", InstrCount[RES]);
      $display("LEA: %d", InstrCount[LEA]);
      $display("TRAP: %d", InstrCount[TRAP]);
      $finish();
    end 
  end 
  
  lc3 LC3(clk, 
          rst,
          memory_dout, 
          memory_addr, 
          memory_din, 
          memWE);
  
   
endmodule