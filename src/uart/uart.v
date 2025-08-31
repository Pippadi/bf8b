module uart #(
    parameter CLOCK_FREQUENCY = 50000000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    output wire tx
);

tx #(
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY),
    .BAUD_RATE(BAUD_RATE)
) TX (
    .rst(rst),
    .clk(clk),
    .data(8'h55), // Transmit ASCII 'U' (0x55)
    .tx(tx)
);

endmodule
