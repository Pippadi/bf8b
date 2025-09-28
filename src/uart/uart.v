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
    input [1:0] reg_select,
    output reg [M_WIDTH-1:0] reg_data_out,
    output reg reg_ready,

    input [M_WIDTH-1:0] tx_mem_data_in,
    input tx_mem_ready,
    output wire tx_mem_req,
    output wire [M_WIDTH-1:0] tx_mem_addr,
    output wire [1:0] tx_mem_width,

    input rx_mem_ready,
    output reg rx_mem_req,
    output wire [M_WIDTH-1:0] rx_mem_addr,
    output wire [1:0] rx_mem_width,
    output wire [M_WIDTH-1:0] rx_mem_data_out,

    input rx,
    output wire tx
);

localparam GENERAL_CFG_ADDR = 2'b00;
localparam TX_SRC_START_ADDR = 2'b01;
localparam TX_SRC_STOP_ADDR = 2'b10;

localparam TX_EN_BIT = 1;
localparam TX_DONE_BIT = 3;

localparam RX_CLKS_PER_BIT = 8;

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

wire [M_WIDTH-1:0] general_cfg;
reg [M_WIDTH-1:0] tx_src_start;
reg [M_WIDTH-1:0] tx_src_stop;
reg tx_en;
wire tx_ptr_rst;
wire tx_done;

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

wire [7:0] rx_data;
rx_deserializer #(
    .RX_CLKS_PER_BIT(RX_CLKS_PER_BIT)
) RX_Deser (
    .rst(rst),
    .clk(clk),
    .rx(rx),
    .rx_clk_posedge(rx_clk_posedge),
    .data(rx_data)
);

assign general_cfg = 0 |
    (tx_en << TX_EN_BIT) |
    (tx_done << TX_DONE_BIT);

assign tx_ptr_rst = reg_req & reg_we & (reg_select == TX_SRC_START_ADDR);

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
                    if (reg_we)
                        tx_en <= reg_data_in[TX_EN_BIT];
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
                default: reg_data_out <= 0;
            endcase
        end
    end
end

endmodule
