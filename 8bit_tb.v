module eightbit_tb();

reg [7:0] mem [0:255];
reg clk;
reg [7:0] addr, data_out, data_in;
wire we;

eightbit eb(
    .clk(clk),
    .addr(addr),
    .data_in(data_out),
    .data_out(data_in),
    .we(we)
);

task pulseClk;
    #0.5 clk = ~clk;
    #0.5 clk = ~clk;
endtask

integer i;
initial begin
    // Load jump instruction
    mem[0] = 8'b00000101;

    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    $dumpvars(0, mem[255]);
    clk = 0;

    for (i = 0; i < 4; i = i + 1)
        pulseClk();
end

always @(posedge clk) begin
    if (we)
        mem[addr] = data_in;
    data_out = mem[addr];
end

endmodule;
