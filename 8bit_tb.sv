`default_nettype none

module eightbit_tb();

reg [7:0] mem [0:255];
reg clk;

eightbit eb(.mem(mem), .clk(clk));

initial begin
    mem[8'hfe] = 8'h01;
    mem[8'hff] = 8'h01;

    mem[8'h00] = 8'h01;
    mem[8'h01] = 8'hfe;
    mem[8'h02] = 8'h06;
    mem[8'h03] = 8'h01;
    mem[8'h04] = 8'hff;
    mem[8'h05] = 8'h10;
    mem[8'h06] = 8'h02;
    mem[8'h07] = 8'hff;

    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    clk = 0;

    forever #1 clk = ~clk;
end

endmodule;
