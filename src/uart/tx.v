module tx
#(
    parameter CLOCK_FREQUENCY = 50000000, // 50 MHz
    parameter BAUD_RATE = 115200
) (
    input rst,
    input clk,
    input [7:0] data,
    output wire tx
);

reg [9:0] tx_ctr;
reg tx_clk;

reg [4:0] bit_cnt;
reg [9:0] tx_byte_buf;

always @(posedge clk) begin
    if (rst) begin
        tx_ctr <= 0;
        tx_clk <= 0;
        bit_cnt <= 0;
        tx_byte_buf <= 10'b0;
    end else begin
        if (tx_ctr == (CLOCK_FREQUENCY / BAUD_RATE) - 1) begin
            tx_ctr <= 0;
            tx_clk <= 0;
        end else begin
            tx_ctr <= tx_ctr + 1;
        end

        if (tx_ctr == (CLOCK_FREQUENCY / (2*BAUD_RATE)))
            tx_clk <= 1;
    end
end

always @(posedge tx_clk) begin
    if (bit_cnt == 0) begin
        tx_byte_buf <= {1'b0, data, 1'b1};
        bit_cnt <= 10;
    end else begin
        tx_byte_buf <= {1'b0, tx_byte_buf[8:1]};
        bit_cnt <= bit_cnt - 1;
    end
end

assign tx = ~tx_byte_buf[0];

endmodule
