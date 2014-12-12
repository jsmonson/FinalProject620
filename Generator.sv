 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction tr;
    event chk2gen;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event chk2gen);
        this.gen2agt = gen2agt;
		this.chk2gen =chk2gen;
    endfunction
    task run(input int count);
       tr = new();
        repeat(count) begin
            `SV_RAND_CHECK(tr.randomize());
	    $display("@%0d: Generator : Sending Transaction",$time);
	    gen2agt.put(tr);
	    @chk2gen;
        end
    endtask
  endclass