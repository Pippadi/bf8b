module eightbit_tb();

reg [7:0] mem [0:255];
reg clk;
reg [7:0] addr, data_out, data_in;
reg we;

eightbit eb(
    .clk(clk),
    .addr(addr),
    .data_in(data_out),
    .data_out(data_in),
    .we(we)
    );

    task pulseClk;
        #1 clk = ~clk;
    endtask

    integer i;
    initial begin
        // load 1s into memory
        mem[8'hfe] = 8'h03;
        mem[8'hff] = 8'h05;

        // Load 1 at 0xfe into a
        mem[8'h00] = 8'h01;
        mem[8'h01] = 8'hfe;
        // Move a to b
        mem[8'h02] = 8'h06;
        // Load 1 at 0xff into a
        mem[8'h03] = 8'h01;
        mem[8'h04] = 8'hff;
        // Add a and b
        mem[8'h05] = 8'h10;
        // Move a to 0xff
        mem[8'h06] = 8'h02;
        mem[8'h07] = 8'hff;
        // Move 0x0a to a
        mem[8'h08] = 8'h01;
        mem[8'h09] = 8'h0a;
        // Move pc to a
        mem[8'h0a] = 8'h03;

        $dumpfile("8bit.vcd");
        $dumpvars(0, eightbit_tb);
        $dumpvars(0, mem[255]);
        clk = 0;

        for (i = 0; i < 400; i = i + 1)
            pulseClk();
    end

    always @(posedge clk) begin
        if (we)
            mem[addr] = data_in;
        data_out = mem[addr];
    end

    endmodule;
