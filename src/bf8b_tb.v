`timescale 10ns / 1ns

module bf8b_tb();

reg rst;
reg clk;

// Banks of individually addressable memories
// for writing to non-32b-aligned addresses
reg [7:0] mem0 [0:1023];
reg [7:0] mem1 [0:1023];
reg [7:0] mem2 [0:1023];
reg [7:0] mem3 [0:1023];

reg [31:0] data_out;
wire [29:0] addr;
wire [31:0] data_in;
wire [3:0] wes;
wire tx;
wire rx;

bf8b #(
    .M_WIDTH(32),
    .REG_CNT(32)
) BF8B (
    .rst(rst),
    .clk(clk),
    .addr(addr),
    .data_in(data_out),
    .data_out(data_in),
    .wes(wes),
    .tx(tx),
    .rx(rx)
);

task pulseClk; begin
    #1 clk = ~clk;
    #1 clk = ~clk;
end
endtask

integer i;
initial begin
    // Memory initialization
    /*** Change me ***/
    $readmemh("fibonacci_block0.hex", mem0);
    $readmemh("fibonacci_block1.hex", mem1);
    $readmemh("fibonacci_block2.hex", mem2);
    $readmemh("fibonacci_block3.hex", mem3);
    /****************/

    $dumpfile("target/bf8b.vcd");
    $dumpvars(0, bf8b_tb);

    // Memory content dump
    /*** Change me ***/
    $dumpvars(0, mem0[8'h38]); // 0x38 = 0xE0 >> 2
    $dumpvars(0, mem1[8'h38]);
    $dumpvars(0, mem2[8'h38]);
    $dumpvars(0, mem3[8'h38]);
    /****************/

    // Register content dump
    for (i = 1; i < 32; i = i + 1) begin
        $dumpvars(0, BF8B.Writeback.reg_file[i]);
    end

    for (i = 0; i < 8; i = i + 1) begin
        $dumpvars(0, BF8B.Fetch.ICache.ShiftReg.q[i]);
    end

    clk = 0;
    fork
        begin
            rst = 1;
            #2;
            rst = 0;
        end

        begin
            for (i = 0; i < 6144; i = i + 1)
                pulseClk();
        end
    join
end

assign rx = 1'b1;

always @(posedge clk) begin
    if (wes[0])
        mem0[addr] <= data_in[0+:8];
    if (wes[1])
        mem1[addr] <= data_in[1*8+:8];
    if (wes[2])
        mem2[addr] <= data_in[2*8+:8];
    if (wes[3])
        mem3[addr] <= data_in[3*8+:8];
    data_out <= {mem3[addr], mem2[addr], mem1[addr], mem0[addr]};
end

endmodule
