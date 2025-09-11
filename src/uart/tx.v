module tx
#(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
) (
    input rst,
    input clk,
    input data_available,
    input [7:0] data,
    output reg req,
    output wire tx,
    output wire busy
);

reg tx_clk;
reg [9:0] tx_byte_buf;
reg [3:0] bit_cnt;
reg data_read;

reg [$clog2(CLK_FREQ/(BAUD_RATE*2)):0] ctr;

always @ (posedge clk) begin
    if (rst) begin
        ctr <= 0;
        tx_clk <= 0;
        bit_cnt <= 0;
        data_read <= 0;
        tx_byte_buf <= 10'b0;
    end else begin
        if (ctr == (CLK_FREQ / BAUD_RATE) - 1) begin
            ctr <= 0;
            tx_clk <= 0;
        end else
            ctr <= ctr + 1;

        if (ctr == CLK_FREQ / (2*BAUD_RATE))
            tx_clk <= 1;

        if (data_available & ~busy & ~data_read) begin
            req <= 1;
            data_read <= 1;
        end else begin
            req <= 0;
        end
    end
end

always @ (posedge tx_clk) begin
    // Possible race condition? Should be fine since data_read is only
    // set when not busy. Hopefully one cycle is enough for data to be valid.
    if (bit_cnt == 0 && data_read) begin
        tx_byte_buf <= {1'b0, data, 1'b1};
        data_read <= 0;
        bit_cnt <= 10;
    end else if (bit_cnt != 0) begin
        tx_byte_buf <= {1'b0, tx_byte_buf[9:1]};
        bit_cnt <= bit_cnt - 1;
    end
end

assign busy = bit_cnt != 0;
assign tx = ~tx_byte_buf[0] | rst;

endmodule
