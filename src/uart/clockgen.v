module clockgen
#(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200,
    parameter RX_CLKS_PER_BIT = 8
) (
    input rst,
    input main_clk,
    output tx_clk_posedge,
    output rx_clk_posedge
);

reg [$clog2(CLK_FREQ*RX_CLKS_PER_BIT*2/BAUD_RATE)-1:0] rx_clk_ctr;
reg [$clog2(RX_CLKS_PER_BIT)-1:0] tx_clk_ctr;
reg tx_clk, tx_clk_prev;
reg rx_clk, rx_clk_prev;

always @ (posedge main_clk or posedge rst) begin
    if (rst) begin
        rx_clk_ctr <= 0;
        rx_clk <= 0;
    end else begin
        // Both of these need to be high for exactly one main_clk cycle
        rx_clk_prev <= rx_clk;
        tx_clk_prev <= tx_clk;

        if (rx_clk_ctr == (CLK_FREQ / (BAUD_RATE * RX_CLKS_PER_BIT)) - 1) begin
            rx_clk_ctr <= 0;
            rx_clk <= 0;
        end else
            rx_clk_ctr <= rx_clk_ctr + 1;

        if (rx_clk_ctr == CLK_FREQ / (2 * BAUD_RATE * RX_CLKS_PER_BIT))
            rx_clk <= 1;
    end
end

always @ (posedge rx_clk or posedge rst) begin
    if (rst) begin
        tx_clk_ctr <= 0;
        tx_clk <= 0;
    end else begin
        if (tx_clk_ctr == RX_CLKS_PER_BIT - 1) begin
            tx_clk_ctr <= 0;
            tx_clk <= 0;
        end else
            tx_clk_ctr <= tx_clk_ctr + 1;

        if (tx_clk_ctr == RX_CLKS_PER_BIT/2)
            tx_clk <= 1;
    end
end

assign tx_clk_posedge = ~tx_clk_prev & tx_clk;
assign rx_clk_posedge = ~rx_clk_prev & rx_clk;

endmodule
