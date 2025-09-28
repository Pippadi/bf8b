module rx_deserializer
#(
    RX_CLKS_PER_BIT = 8
)
(
    input rst,
    input clk,
    input rx,
    input deser_clk_posedge,
    output reg [7:0] data,
    output reg latch_data
);

reg [$clog2(RX_CLKS_PER_BIT)-1:0] clk_count;
reg [$clog2(10)-1:0] bit_idx;
reg line_active;
reg data_latched;

wire should_latch_data;
assign should_latch_data = (clk_count == (RX_CLKS_PER_BIT-1)/2) && (bit_idx < 8);

always @ (posedge clk) begin
    if (rst) begin
        data <= 'b0;
        latch_data <= 'b0;
        clk_count <= 'b0;
        bit_idx <= 'b0;
    end else begin
        if (~line_active & ~rx) begin
            line_active <= 'b1;
            clk_count <= 'b0;
            bit_idx <= 'b0;
            latch_data <= 'b0;
            data_latched <= 'b0;
        end

        if (deser_clk_posedge & line_active) begin
            if (bit_idx == 9) begin
                line_active <= 'b0;
                clk_count <= 'b0;
                bit_idx <= 'b0;
                latch_data <= 'b0;
            end else begin
                if (should_latch_data) begin
                    data <= {rx, data[7:1]};
                    clk_count <= clk_count + 1'b1;
                end

                if (clk_count == RX_CLKS_PER_BIT-1) begin
                    clk_count <= 'b0;
                    bit_idx <= bit_idx + 1'b1;
                end else
                    clk_count <= clk_count + 1'b1;
            end
        end

        if (bit_idx == 9 && !data_latched) begin
            latch_data <= 1'b1;
            data_latched <= 1'b1;
        end else
            latch_data <= 1'b0;
    end
end

endmodule
