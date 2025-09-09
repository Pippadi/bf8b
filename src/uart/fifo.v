module fifo
#(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8
) (
    input rst,
    input clk,
    input write_en,
    input read_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg full,
    output reg empty
);

localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;
reg [ADDR_WIDTH:0] buffered_cnt;

always @ (posedge clk) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        buffered_cnt <= 0;
        full <= 0;
        empty <= 1;
        data_out <= 0;
    end else begin
        if (write_en && !full) begin
            fifo_mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
            buffered_cnt <= buffered_cnt + 1;
        end

        if (read_en && !empty) begin
            data_out <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            buffered_cnt <= buffered_cnt - 1;
        end

        full <= (buffered_cnt == FIFO_DEPTH);
        empty <= (buffered_cnt == 0);
    end
end

endmodule
