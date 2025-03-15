`timescale 1ns / 1ps

module eightbit_tb();

reg rst;
reg clk;

reg [7:0] mem [0:255];
wire [7:0] addr;
reg mem_ready;
wire mem_req;
reg [7:0] mem_data_out;
wire [7:0] mem_data_in;
wire we;

eightbit eb(
    .rst(rst),
    .clk(clk),
    .addr(addr),
    .mem_ready(mem_ready),
    .data_in(mem_data_out),
    .data_out(mem_data_in),
    .mem_req(mem_req),
    .we(we)
);

task pulseClk; begin
    #0.5 clk = ~clk;
    #0.5 clk = ~clk;
end
endtask

integer i;
initial begin
    // Load a with 0x01
    mem[8'h00] = 8'b01000000;
    mem[8'hE0] = 8'h01;

    // Load b with 0x01
    mem[8'h01] = 8'b01100010;
    mem[8'hE2] = 8'h00;

    // Loop top
    // Store a at 0xE0
    mem[8'h02] = 8'b10000000;

    // Add a and b, and store sum in a
    mem[8'h03] = 8'b11000000;

    // Load b with a's previous value at 0xE0
    mem[8'h04] = 8'b01100000;

    // Jump to top of loop
    mem[8'h05] = 8'b00000010;

    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    $dumpvars(0, mem[8'hE0]);
    rst = 1;
    #1;
    rst = 0;
    clk = 0;

    for (i = 0; i < 512; i = i + 1)
        pulseClk();
end

always @(posedge clk) begin
    mem_ready = 0;
    if (mem_req) begin
        if (we)
            mem[addr] = mem_data_in;
        mem_data_out = mem[addr];
        mem_ready = 1;
    end
end

endmodule;
