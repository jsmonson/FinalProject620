 class Generator;
    mailbox #(MemoryTransaction) gen2agt;
    MemoryTransaction blueprint, temp;
    event chk2gen;
	int id = 0;
    function new(input mailbox #(MemoryTransaction) gen2agt, input event chk2gen);
        this.gen2agt = gen2agt;
		this.chk2gen = chk2gen;
		this.blueprint = new();
    endfunction
    task run(input int count);
		//$display("@%0d: Generator : Blueprint %d",$time, blueprint.ID());
        repeat(count) begin
			`SV_RAND_CHECK(blueprint.randomize());
			temp = blueprint.copy(id++);
			$display("@%0d: Generator : Sending Transaction %0d",$time, temp.ID());
			gen2agt.put(temp);
			@chk2gen;
        end
    endtask
  endclass