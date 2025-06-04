`timescale 1ns / 1ps

module eightbit_tb();

reg rst;
reg clk;

// Banks of individually addressable memories
// for writing to non-32b-aligned addresses
reg [7:0] mem0 [0:1024];
reg [7:0] mem1 [0:1024];
reg [7:0] mem2 [0:1024];
reg [7:0] mem3 [0:1024];

reg [31:0] data_out;
wire [29:0] addr;
wire [31:0] data_in;
wire [3:0] wes;

eightbit #(
    .M_WIDTH(32),
    .REG_CNT(32)
) eb (
    .rst(rst),
    .clk(clk),
    .addr(addr),
    .data_in(data_out),
    .data_out(data_in),
    .wes(wes)
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
    if (wes[0])
        mem0[addr] <= data_in[7:0];
    if (wes[1])
        mem1[addr] <= data_in[15:8];
    if (wes[2])
        mem2[addr] <= data_in[23:16];
    if (wes[3])
        mem3[addr] <= data_in[31:24];
    data_out <= {mem3[addr], mem2[addr], mem1[addr], mem0[addr]};
end

endmodule
