module rx_manager
#(
    parameter M_WIDTH = 32,
    parameter MEM_ACC_8 = 2'b00,
    parameter MEM_ACC_16 = 2'b01,
    parameter MEM_ACC_32 = 2'b10,
    parameter RX_CLKS_PER_BIT = 8
)
(
    input rst,
    input clk,

    input en,
    input deser_clk_posedge,
    input ptr_rst,
    input [M_WIDTH-1:0] dma_buf_start,
    input [M_WIDTH-1:0] dma_buf_end,
    output wire dma_buf_full,
    output reg [M_WIDTH-1:0] ptr,

    input mem_ready,
    output reg mem_req,
    output wire [M_WIDTH-1:0] mem_addr,
    output wire [1:0] mem_width,
    output wire [M_WIDTH-1:0] mem_data_out,

    input rx
);

reg [1:0] mem_cycle;
wire should_req;
localparam RX_IDLE = 0;
localparam RX_DATA_READY = 1;
localparam RX_MEM_WAITING = 2;
localparam RX_MEM_READY = 3;

wire [7:0] deser_data;
wire [7:0] fifo_data_out;
wire fifo_full;
wire fifo_empty;
wire fifo_write_en;
reg fifo_read_en;

rx_deserializer #(
    .RX_CLKS_PER_BIT(RX_CLKS_PER_BIT)
) RX_Deser (
    .rst(rst),
    .clk(clk),
    .deser_clk_posedge(deser_clk_posedge),
    .data(deser_data),
    .latch_data(fifo_write_en),
    .rx(rx)
);

fifo #(
    .DATA_WIDTH(8),
    .FIFO_DEPTH(8)
) RXFIFO (
    .rst(~en | rst),
    .clk(clk),
    .data_in(deser_data),
    .write_en(fifo_write_en),
    .read_en(fifo_read_en),
    .data_out(fifo_data_out),
    .full(fifo_full),
    .empty(fifo_empty)
);

assign mem_addr = ptr;
assign mem_width = MEM_ACC_8;
assign mem_data_out = {24'b0, fifo_data_out};
assign dma_buf_full = en & (ptr == dma_buf_end);
assign should_req = en & ~fifo_empty & ~dma_buf_full;

always @ (*) begin
    mem_req = 0;
    fifo_read_en = 0;

    if (en) begin
        case (mem_cycle)
            RX_IDLE: fifo_read_en = should_req;
            RX_MEM_WAITING: mem_req = 1;
        endcase
    end
end

always @ (posedge clk) begin
    if (rst) begin
        mem_cycle <= RX_IDLE;
        ptr <= 0;
    end else begin
        if (ptr_rst) begin
            ptr <= dma_buf_start;
            mem_cycle <= RX_IDLE;
        end else begin
            if (en) begin
                case (mem_cycle)
                    RX_IDLE: mem_cycle <= should_req ? RX_DATA_READY : RX_IDLE;
                    RX_DATA_READY: mem_cycle <= RX_MEM_WAITING;
                    RX_MEM_WAITING: mem_cycle <= mem_ready ? RX_MEM_READY : RX_MEM_WAITING;
                    RX_MEM_READY: begin
                        mem_cycle <= RX_IDLE;
                        ptr <= ptr + 1;
                    end
                endcase
            end else
                mem_cycle <= RX_IDLE;
        end
    end
end

endmodule
