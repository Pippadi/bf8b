module uart #(
    parameter M_WIDTH = 32,
    parameter CLOCK_FREQUENCY = 50000000,
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
    output reg [M_WIDTH-1:0] reg_data_out,
    output reg [1:0] reg_select,
    output reg reg_ready,

    input [M_WIDTH-1:0] tx_mem_data_in,
    input tx_mem_ready,
    output reg tx_mem_req,
    output wire [M_WIDTH-1:0] tx_mem_addr,
    output wire [1:0] tx_mem_width,

    output wire tx
);

localparam GENERAL_CFG_ADDR = 2'b00;
localparam TX_SRC_START_ADDR = 2'b01;
localparam TX_SRC_STOP_ADDR = 2'b10;

localparam TX_EN_BIT = 1;
localparam TX_DONE_BIT = 3;

localparam GENERAL_CFG_WRITE_MASK = 32'hFFFF_FFFF ^ (1 << TX_DONE_BIT);

reg [M_WIDTH-1:0] general_cfg;
reg [M_WIDTH-1:0] tx_src_start;
reg [M_WIDTH-1:0] tx_src_stop;

reg [M_WIDTH-1:0] tx_ptr;
reg [1:0] tx_mem_cycle;
wire tx_should_req;
localparam TX_MEM_IDLE = 0;
localparam TX_MEM_WAITING = 1;
localparam TX_MEM_READY = 2;

wire [7:0] tx_data;
wire tx_fifo_full;
wire tx_fifo_empty;
reg tx_fifo_write_en;
wire tx_phy_data_req;
wire tx_busy;

tx TX (
    .rst(rst),
    .clk(clk),
    .data(tx_data),
    .data_available(~tx_fifo_empty),
    .busy(tx_busy),
    .req(tx_phy_data_req),
    .tx(tx)
);

fifo #(
    .DATA_WIDTH(8),
    .FIFO_DEPTH(8)
) TXFIFO (
    .rst(rst),
    .clk(clk),
    .data_in(tx_mem_data_in[7:0]),
    .write_en(tx_fifo_write_en),
    .read_en(tx_phy_data_req),
    .data_out(tx_data),
    .full(tx_fifo_full),
    .empty(tx_fifo_empty)
);

assign tx_mem_addr = tx_ptr;
assign tx_mem_width = MEM_ACC_8;
assign tx_should_req = ~tx_fifo_full & ~tx_mem_req & (tx_ptr == tx_src_stop);

always @ (*) begin
    general_cfg[TX_DONE_BIT] = (tx_ptr == tx_src_stop);
    tx_mem_req = 0;
    tx_fifo_write_en = 0;

    if (general_cfg[TX_DONE_BIT] & ~general_cfg[TX_DONE_BIT]) begin
        case (tx_mem_cycle)
            TX_MEM_WAITING: tx_mem_req = 1;
            TX_MEM_READY: tx_fifo_write_en = 1;
        endcase
    end
end

always @ (posedge clk) begin
    if (rst) begin
        general_cfg <= 0;
        tx_src_start <= 0;
        tx_src_stop <= 0;
        reg_data_out <= 0;
        reg_select <= 0;
        reg_ready <= 0;
        tx_mem_cycle <= TX_MEM_IDLE;
        tx_ptr <= 0;
    end else begin
        reg_ready <= reg_req;
        if (reg_req) begin
            case (reg_select)
                GENERAL_CFG_ADDR: begin
                    reg_data_out <= general_cfg;
                    if (reg_we)
                        general_cfg <= reg_data_in & GENERAL_CFG_WRITE_MASK;
                end
                TX_SRC_START_ADDR: begin
                    reg_data_out <= tx_src_start;
                    if (reg_we) begin
                        tx_src_start <= reg_data_in;
                        tx_ptr <= reg_data_in;
                    end
                end
                TX_SRC_STOP_ADDR: begin
                    reg_data_out <= tx_src_stop;
                    if (reg_we)
                        tx_src_stop <= reg_data_in;
                end
                default: reg_data_out <= 0;
            endcase
        end

        if (general_cfg[TX_EN_BIT] & ~general_cfg[TX_DONE_BIT]) begin
            case (tx_mem_cycle)
                TX_MEM_IDLE: tx_mem_cycle <= tx_should_req ? TX_MEM_WAITING : TX_MEM_IDLE;
                TX_MEM_WAITING: tx_mem_cycle <= tx_mem_ready ? TX_MEM_READY : TX_MEM_WAITING;
                TX_MEM_READY: begin
                    tx_mem_cycle <= TX_MEM_IDLE;
                    tx_ptr <= tx_ptr + 1;
                end
            endcase
        end else
            tx_mem_cycle <= TX_MEM_IDLE;
    end
end

endmodule
