 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction tr;
    event chk2gen;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event chk2gen);
        this.gen2agt = gen2agt;
		this.chk2gen =chk2gen;
    endfunction
	Opcode op;
    task run(input int count);
        repeat(count) begin
            tr = new();
            `SV_RAND_CHECK(tr.randomize());
            gen2agt.put(tr);
			wait (chk2gen.triggered);
        end
    endtask
  endclass