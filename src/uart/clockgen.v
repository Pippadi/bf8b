module clockgen
#(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
) (
    input rst,
    input clk,
    output tx_clk_posedge
);

reg [$clog2(CLK_FREQ/(BAUD_RATE*2)):0] ctr;
reg tx_clk;
reg tx_clk_prev;

always @ (posedge clk) begin
    if (rst) begin
        ctr <= 0;
        tx_clk <= 0;
        tx_clk_prev <= 0;
    end else begin
        tx_clk_prev <= tx_clk;

        if (ctr == (CLK_FREQ / BAUD_RATE) - 1) begin
            ctr <= 0;
            tx_clk <= 0;
        end else
            ctr <= ctr + 1;

        if (ctr == CLK_FREQ / (2*BAUD_RATE))
            tx_clk <= 1;
    end
end

assign tx_clk_posedge = ~tx_clk_prev & tx_clk;

endmodule
