covergroup Cov();
    option.per_instance = 1;
    opcodes: coverpoint state {  } // make sure each opcode exe
    src: coverpoint tr.data_out[3:2];
    dst: coverpoint tr.data_out[1:0];
    preceded_followed: coverpoint state { // all instruction transitions
        ignore_bins exc = {BR,BRZ,HALT}; 
        bins states[] = (NOP,ADD,SUB,AND,NOT,RD,WR,RDI => NOP,ADD,SUB,AND,NOT,RD,WR,RDI);
    } 
    permuations: cross src, dst iff (state==ADD || state==SUB || state==AND || state==NOT);
    wr_address: coverpoint env.drv.address iff (state==WR);
    rd_address: coverpoint env.drv.address iff (state==RD);   
endgroup
