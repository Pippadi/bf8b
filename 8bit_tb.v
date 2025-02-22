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
    mem[8'h00] = 8'b00000101;

    // Load a with 0x0F
    mem[8'h05] = 8'b01000001;
    mem[8'hE1] = 8'h0F;

    // Load b with 0x01
    mem[8'h06] = 8'b01100000;
    mem[8'hE0] = 8'h01;

    // Add a and b, and store sum in a
    mem[8'h07] = 8'b11000000;

    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    $dumpvars(0, mem[8'hE0]);
    clk = 0;

    for (i = 0; i < 32; i = i + 1)
        pulseClk();
end

always @(posedge clk) begin
    if (we)
        mem[addr] = data_in;
    data_out = mem[addr];
end

endmodule;
