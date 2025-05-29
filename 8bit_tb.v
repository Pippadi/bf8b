`timescale 1ns / 1ps

module eightbit_tb();

reg rst;
reg clk;

reg [7:0] mem [0:4095];
reg [31:0] data_out;
wire [31:0] addr;
wire [31:0] data_in;
wire we;

eightbit #(
    .M_WIDTH(32),
    .REG_CNT(32)
) eb (
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
    $readmemh("fibonacci.hex", mem);
    $dumpfile("8bit.vcd");
    $dumpvars(0, eightbit_tb);
    $dumpvars(0, mem[8'hE3]);
    $dumpvars(0, mem[8'hE2]);
    $dumpvars(0, mem[8'hE1]);
    $dumpvars(0, mem[8'hE0]);
    $dumpvars(0, eb.Writeback.reg_file[10]); // a0
    $dumpvars(0, eb.Writeback.reg_file[11]); // a1
    $dumpvars(0, eb.Writeback.reg_file[12]); // a2

    for (i = 0; i < 8; i = i + 1) begin
        $dumpvars(0, eb.Fetch.ICache.ShiftReg.q[i]);
    end

    clk = 0;
    fork
        begin
            rst = 1;
            #2;
            rst = 0;
        end

        begin
            for (i = 0; i < 512; i = i + 1)
                pulseClk();
        end
    join
end

always @(posedge clk) begin
    if (we) begin
        {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= data_in;
    end
    data_out <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
end

endmodule
