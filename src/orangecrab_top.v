`timescale 10ns / 1ns

module top(
    input clk48,
    input usr_btn,
    output gpio_13,
    output gpio_12,
    output gpio_11,
    output gpio_10,
    output rgb_led0_r,
    output rgb_led0_g,
    output rgb_led0_b
);

wire clk30;

pll PLL_Inst (
    .clkin(clk48),
    .clkout0(clk30),
    .locked(pll_locked)
);

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
wire rst;

assign rst = ~usr_btn | ~pll_locked;
assign rgb_led0_r = tx;
assign rgb_led0_g = ~pll_locked;
assign rgb_led0_b = |wes;

bf8b #(
    .M_WIDTH(32),
    .REG_CNT(32),
    .CLK_FREQ(30000000)
) BF8B (
    .rst(rst),
    .clk(clk30),
    .addr(addr),
    .data_in(data_out),
    .data_out(data_in),
    .wes(wes),
    .tx(tx),
    .rx(rx)
);

initial begin
    // Memory initialization
    /*** Change me ***/
    $readmemh("ram_block0.hex", mem0);
    $readmemh("ram_block1.hex", mem1);
    $readmemh("ram_block2.hex", mem2);
    $readmemh("ram_block3.hex", mem3);
    /****************/
end

assign rx = tx;
assign gpio_13 = tx;
assign gpio_11 = addr[0];
assign gpio_12 = addr[1];
assign gpio_10 = rst;
assign gpio_9 = clk30;
assign gpio_6 = |wes;
assign gpio_5 = clk48;

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

