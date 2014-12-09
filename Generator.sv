 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction tr;
    event gen2agths, chk2gen;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event gen2agths, chk2gen);
        this.gen2agt = gen2agt;
        this.gen2agths = gen2agths;
		this.chk2gen =chk2gen;
    endfunction
    task run(input int count);
        repeat(count) begin
            tr = new();
            `SV_RAND_CHECK(tr.randomize());
            gen2agt.put(tr);
            wait (gen2agths.triggered);
        end
    endtask
  endclass