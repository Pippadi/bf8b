`timescale 1ns / 1ps

module eightbit_tb();

reg rst;
reg clk;

reg [7:0] mem [0:255];
wire [7:0] addr;
reg mem_ready;
wire mem_req;
wire [7:0] mem_data;
wire we;

eightbit eb(
    .rst(rst),
    .clk(clk),
    .addr(addr),
    .mem_ready(mem_ready),
    .data(mem_data),
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
    mem[8'h00] = 8'b00010000;
    mem[8'h01] = 8'hE0;
    mem[8'hE0] = 8'h01;

    // Load b with 0x00
    mem[8'h02] = 8'b00010001;
    mem[8'h03] = 8'hE2;
    mem[8'hE2] = 8'h00;

    // Loop top
    // Store a at 0xE0
    mem[8'h04] = 8'b00100000;
    mem[8'h05] = 8'hE0;

    // Add a and b, and store sum in a
    mem[8'h06] = 8'b00110000;
    mem[8'h07] = 8'b00010000;

    // Load b with a's previous value at 0xE0
    mem[8'h08] = 8'b00010001;
    mem[8'h09] = 8'hE0;

    // Jump to top of loop
    mem[8'h0A] = 8'h00;
    mem[8'h0B] = 8'h04;

    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    $dumpvars(0, mem[8'hE0]);
    $dumpvars(0, eb.reg_file[0]);
    $dumpvars(0, eb.reg_file[1]);
    rst = 1;
    #1;
    rst = 0;
    clk = 0;

    for (i = 0; i < 512; i = i + 1)
        pulseClk();
end

assign mem_data = (we) ? 8'hzz : mem[addr];

always @(posedge clk) begin
    mem_ready = mem_req;
    if (we)
        mem[addr] = mem_data;
end

endmodule;
