`timescale 1ns / 1ps

module eightbit_tb();

reg rst;
reg clk;

reg [7:0] mem [0:255];
reg [7:0] data_out;
wire [7:0] addr;
wire [7:0] data_in;
wire we;

eightbit eb(
    .rst(rst),
    .clk(clk),
    .addr(addr),
    .data_in(data_out),
    .data_out(data_in),
    .we(we)
);

task pulseClk; begin
    #0.5 clk = ~clk;
    #0.5 clk = ~clk;
end
endtask

integer i;
initial begin
    // Load r0 with 0x01
    mem[8'h00] = 8'h50;
    mem[8'h01] = 8'h01;

    // Load r1 with 0x00
    mem[8'h02] = 8'h51;
    mem[8'h03] = 8'h00;

    // Load r15 with 0xE0
    mem[8'h04] = 8'h5F;
    mem[8'h05] = 8'hE0;

    // Load r14 with 0x08
    mem[8'h06] = 8'h5E;
    mem[8'h07] = 8'h08;

    // Loop top
    // Store r0 at 0xE0
    mem[8'h08] = 8'h20;
    mem[8'h09] = 8'hF0;

    // Back up r0 to r2
    mem[8'h0A] = 8'h42;
    mem[8'h0B] = 8'h00;

    // Add r0 and r1, and store sum in r0
    mem[8'h0C] = 8'h30;
    mem[8'h0D] = 8'h10;

    // Load r1 with r0's previous value from r2
    mem[8'h0E] = 8'h41;
    mem[8'h0F] = 8'h20;

    // Jump to top of loop
    mem[8'h10] = 8'h0E;
    mem[8'h11] = 8'h00;

    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    $dumpvars(0, mem[8'hE0]);
    $dumpvars(0, eb.Writeback.reg_file[0]);
    $dumpvars(0, eb.Writeback.reg_file[1]);
    $dumpvars(0, eb.Writeback.reg_file[2]);

    for (i = 0; i < 8; i = i + 1) begin
        $dumpvars(0, eb.Fetch.ICache.ShiftReg.q[i]);
    end

    rst = 1;
    #1;
    rst = 0;
    clk = 0;

    for (i = 0; i < 512; i = i + 1)
        pulseClk();
end

always @(posedge clk) begin
        if (we)
            mem[addr] <= data_in;
        data_out <= mem[addr];
end

endmodule;
