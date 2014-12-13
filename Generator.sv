 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction tr;
    event chk2gen;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event chk2gen);
        this.gen2agt = gen2agt;
		this.chk2gen =chk2gen;
    endfunction
    task run(input int count);
       int id = 0;
       tr = new();
        repeat(count) begin
            `SV_RAND_CHECK(tr.randomize());
	    tr.id = id++;
	    $display("@%0d: Generator : Sending Transaction %0d",$time,tr.id);
	    gen2agt.put(tr);
	    @chk2gen;
        end
    endtask
  endclass