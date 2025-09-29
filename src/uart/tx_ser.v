module tx_serializer
(
    input rst,
    input clk,
    input ser_clk_posedge,
    input data_available,
    input [7:0] data,
    output reg req,
    output wire tx,
    output wire busy
);

reg [9:0] tx_byte_buf;
reg [3:0] bit_cnt;
reg data_read;

always @ (posedge clk) begin
    if (rst) begin
        bit_cnt <= 0;
        data_read <= 0;
        tx_byte_buf <= 10'b0;
    end else begin
        if (data_available & ~busy & ~data_read) begin
            req <= 1;
            data_read <= 1;
        end else
            req <= 0;

        if (ser_clk_posedge) begin
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
    end
end

assign busy = bit_cnt != 0;
assign tx = ~tx_byte_buf[0] | rst;

endmodule
