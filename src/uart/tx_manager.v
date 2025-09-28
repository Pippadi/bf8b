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

    input tx_en,
    input tx_clk_posedge,
    input tx_ptr_rst,
    input [M_WIDTH-1:0] tx_src_start,
    input [M_WIDTH-1:0] tx_src_stop,
    output wire tx_done,

    input [M_WIDTH-1:0] tx_mem_data_in,
    input tx_mem_ready,
    output reg tx_mem_req,
    output wire [M_WIDTH-1:0] tx_mem_addr,
    output wire [1:0] tx_mem_width,

    output wire tx
);

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

tx_serializer TX_Ser (
    .rst(rst),
    .clk(clk),
    .tx_clk_posedge(tx_clk_posedge),
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
assign tx_should_req = ~tx_fifo_full & (tx_mem_cycle == TX_MEM_IDLE) & (tx_ptr != tx_src_stop);
assign tx_done = tx_en & (tx_ptr == tx_src_stop) & ~tx_busy;

always @ (*) begin
    tx_mem_req = 0;
    tx_fifo_write_en = 0;

    if (tx_en & ~tx_done) begin
        case (tx_mem_cycle)
            TX_MEM_WAITING: tx_mem_req = 1;
            TX_MEM_READY: tx_fifo_write_en = 1;
        endcase
    end
end

always @ (posedge clk) begin
    if (rst) begin
        tx_mem_cycle <= TX_MEM_IDLE;
        tx_ptr <= 0;
    end else begin
        if (tx_ptr_rst) begin
            tx_ptr <= tx_src_start;
            tx_mem_cycle <= TX_MEM_IDLE;
        end else begin
            if (tx_en & ~tx_done) begin
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
end

endmodule
