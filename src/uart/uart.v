module uart #(
    parameter M_WIDTH = 32,
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200,

    parameter MEM_ACC_8 = 2'b00,
    parameter MEM_ACC_16 = 2'b01,
    parameter MEM_ACC_32 = 2'b10
) (
    input rst,
    input clk,

    input reg_req,
    input reg_we,
    input [M_WIDTH-1:0] reg_data_in,
    input [2:0] reg_select,
    output reg [M_WIDTH-1:0] reg_data_out,
    output reg reg_ready,

    input [M_WIDTH-1:0] tx_mem_data_in,
    input tx_mem_ready,
    output wire tx_mem_req,
    output wire [M_WIDTH-1:0] tx_mem_addr,
    output wire [1:0] tx_mem_width,

    input rx_mem_ready,
    output wire rx_mem_req,
    output wire [M_WIDTH-1:0] rx_mem_addr,
    output wire [1:0] rx_mem_width,
    output wire [M_WIDTH-1:0] rx_mem_data_out,

    input rx,
    output wire tx
);

localparam GENERAL_CFG_ADDR = 3'b000;
localparam TX_SRC_START_ADDR = 3'b001;
localparam TX_SRC_STOP_ADDR = 3'b010;
localparam RX_DMA_BUF_START_ADDR = 3'b011;
localparam RX_DMA_BUF_END_ADDR = 3'b100;
localparam RX_DMA_BUF_PTR_ADDR = 3'b101;

localparam TX_EN_BIT = 1;
localparam TX_DONE_BIT = 3;
localparam RX_EN_BIT = 2;
localparam RX_DMA_BUF_FULL_BIT = 4;
localparam RX_PTR_RST_BIT = 5;

localparam RX_CLKS_PER_BIT = 8;

wire [M_WIDTH-1:0] general_cfg;
reg [M_WIDTH-1:0] tx_src_start;
reg [M_WIDTH-1:0] tx_src_stop;
reg [M_WIDTH-1:0] rx_dma_buf_start;
reg [M_WIDTH-1:0] rx_dma_buf_end;
reg tx_en;
wire tx_done;
reg rx_en;
wire rx_dma_buf_full;

wire tx_clk_posedge;
wire rx_clk_posedge;

clockgen #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .RX_CLKS_PER_BIT(RX_CLKS_PER_BIT)
) ClkGen (
    .rst(rst),
    .main_clk(clk),
    .tx_clk_posedge(tx_clk_posedge),
    .rx_clk_posedge(rx_clk_posedge)
);

wire tx_ptr_rst;

tx_manager #(
    .M_WIDTH(M_WIDTH),
    .MEM_ACC_8(MEM_ACC_8),
    .MEM_ACC_16(MEM_ACC_16),
    .MEM_ACC_32(MEM_ACC_32)
) TX_Manager (
    .rst(rst),
    .clk(clk),

    .tx_en(tx_en),
    .tx_clk_posedge(tx_clk_posedge),
    .tx_ptr_rst(tx_ptr_rst),
    .tx_src_start(tx_src_start),
    .tx_src_stop(tx_src_stop),
    .tx_done(tx_done),

    .tx_mem_data_in(tx_mem_data_in),
    .tx_mem_ready(tx_mem_ready),
    .tx_mem_req(tx_mem_req),
    .tx_mem_addr(tx_mem_addr),
    .tx_mem_width(tx_mem_width),

    .tx(tx)
);

wire rx_ptr_rst;
wire [M_WIDTH-1:0] rx_ptr;

rx_manager #(
    .M_WIDTH(M_WIDTH),
    .MEM_ACC_8(MEM_ACC_8),
    .MEM_ACC_16(MEM_ACC_16),
    .MEM_ACC_32(MEM_ACC_32),
    .RX_CLKS_PER_BIT(RX_CLKS_PER_BIT)
) RX_Manager (
    .rst(rst),
    .clk(clk),

    .en(rx_en),
    .deser_clk_posedge(rx_clk_posedge),
    .ptr_rst(rx_ptr_rst),
    .dma_buf_start(rx_dma_buf_start),
    .dma_buf_end(rx_dma_buf_end),
    .dma_buf_full(rx_dma_buf_full),
    .ptr(rx_ptr),

    .mem_ready(rx_mem_ready),
    .mem_req(rx_mem_req),
    .mem_addr(rx_mem_addr),
    .mem_width(rx_mem_width),
    .mem_data_in(rx_mem_data_out),

    .rx(rx)
);

assign general_cfg = 0 |
    (tx_en << TX_EN_BIT) |
    (rx_en << RX_EN_BIT) |
    (tx_done << TX_DONE_BIT) |
    (rx_dma_buf_full << RX_DMA_BUF_FULL_BIT);

assign tx_ptr_rst = reg_req & reg_we & (reg_select == TX_SRC_START_ADDR);
assign rx_ptr_rst = reg_req & reg_we & (reg_select == RX_DMA_BUF_PTR_ADDR) & reg_data_in[RX_PTR_RST_BIT];

always @ (posedge clk) begin
    if (rst) begin
        tx_en <= 0;
        tx_src_start <= 0;
        tx_src_stop <= 0;
        reg_data_out <= 0;
        reg_ready <= 0;
    end else begin
        reg_ready <= reg_req;
        if (reg_req) begin
            case (reg_select)
                GENERAL_CFG_ADDR: begin
                    reg_data_out <= general_cfg;
                    if (reg_we) begin
                        tx_en <= reg_data_in[TX_EN_BIT];
                        rx_en <= reg_data_in[RX_EN_BIT];
                    end
                end
                TX_SRC_START_ADDR: begin
                    reg_data_out <= tx_src_start;
                    if (reg_we)
                        tx_src_start <= reg_data_in;
                end
                TX_SRC_STOP_ADDR: begin
                    reg_data_out <= tx_src_stop;
                    if (reg_we)
                        tx_src_stop <= reg_data_in;
                end
                RX_DMA_BUF_START_ADDR: begin
                    reg_data_out <= rx_dma_buf_start;
                    if (reg_we)
                        rx_dma_buf_start <= reg_data_in;
                end
                RX_DMA_BUF_END_ADDR: begin
                    reg_data_out <= rx_dma_buf_end;
                    if (reg_we)
                        rx_dma_buf_end <= reg_data_in;
                end
                RX_DMA_BUF_PTR_ADDR: reg_data_out <= rx_ptr;
                default: reg_data_out <= 0;
            endcase
        end
    end
end

endmodule
