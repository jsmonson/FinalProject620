 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction tr;
    event gen2agths, chk2gen;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event gen2agths, chk2gen);
        this.gen2agt = gen2agt;
        this.gen2agths = gen2agths;
		this.chk2gen =chk2gen;
    endfunction
	int tr_num;
	Opcode op;
    task run(input int count);
        repeat(count) begin
            tr = new();
            `SV_RAND_CHECK(tr.randomize());
			tr.isInstr = 1'b1;
            gen2agt.put(tr);
			tr_num =  mem_access_cnt[$cast(cp,tr.DataOut[15:12])];
			repeat(tr_num) begin
				
			end
        end
    endtask
  endclass