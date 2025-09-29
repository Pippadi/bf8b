module tx_manager
#(
    parameter M_WIDTH = 32,
    parameter MEM_ACC_8 = 2'b00,
    parameter MEM_ACC_16 = 2'b01,
    parameter MEM_ACC_32 = 2'b10
)
(
    input rst,
    input clk,

    input en,
    input ser_clk_posedge,
    input ptr_rst,
    input [M_WIDTH-1:0] dma_buf_start,
    input [M_WIDTH-1:0] dma_buf_end,
    output wire done,

    input [M_WIDTH-1:0] mem_data_in,
    input mem_ready,
    output reg mem_req,
    output wire [M_WIDTH-1:0] mem_addr,
    output wire [1:0] mem_width,

    output wire tx
);

reg [M_WIDTH-1:0] ptr;
reg [1:0] mem_cycle;
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

tx_serializer TX_Ser (
    .rst(rst),
    .clk(clk),
    .ser_clk_posedge(ser_clk_posedge),
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
    .data_in(mem_data_in[7:0]),
    .write_en(tx_fifo_write_en),
    .read_en(tx_phy_data_req),
    .data_out(tx_data),
    .full(tx_fifo_full),
    .empty(tx_fifo_empty)
);

assign mem_addr = ptr;
assign mem_width = MEM_ACC_8;
assign tx_should_req = ~tx_fifo_full & (mem_cycle == TX_MEM_IDLE) & (ptr != dma_buf_end);
assign done = en & (ptr == dma_buf_end) & ~tx_busy;

always @ (*) begin
    mem_req = 0;
    tx_fifo_write_en = 0;

    if (en & ~done) begin
        case (mem_cycle)
            TX_MEM_WAITING: mem_req = 1;
            TX_MEM_READY: tx_fifo_write_en = 1;
        endcase
    end
end

always @ (posedge clk) begin
    if (rst) begin
        mem_cycle <= TX_MEM_IDLE;
        ptr <= 0;
    end else begin
        if (ptr_rst) begin
            ptr <= dma_buf_start;
            mem_cycle <= TX_MEM_IDLE;
        end else begin
            if (en & ~done) begin
                case (mem_cycle)
                    TX_MEM_IDLE: mem_cycle <= tx_should_req ? TX_MEM_WAITING : TX_MEM_IDLE;
                    TX_MEM_WAITING: mem_cycle <= mem_ready ? TX_MEM_READY : TX_MEM_WAITING;
                    TX_MEM_READY: begin
                        mem_cycle <= TX_MEM_IDLE;
                        ptr <= ptr + 1;
                    end
                endcase
            end else
                mem_cycle <= TX_MEM_IDLE;
        end
    end
end

endmodule
