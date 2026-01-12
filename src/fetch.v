module fetch
#(
    parameter M_WIDTH = 8,
    parameter INST_WIDTH = 16
)
(
    input rst,
    input en,
    input clk,
    input [M_WIDTH-1:0] data_in,
    input [M_WIDTH-1:0] pc,
    input mem_ready,
    output reg [M_WIDTH-1:0] addr,
    output reg [INST_WIDTH-1:0] inst_out,
    output reg mem_req,
    output reg ready
);

localparam QUERY_CACHE = 2'b00;
localparam MEM_WAIT = 2'b01;
localparam UPDATE_CACHE = 2'b10;
localparam DONE = 2'b11;

reg cache_req, cache_we;
wire cache_hit, cache_ready;
wire [INST_WIDTH-1:0] cache_inst;

cache #(
    .DATA_WIDTH(INST_WIDTH),
    .ADDR_WIDTH(M_WIDTH),
    .CELL_CNT(32)
) ICache (
    .rst(rst),
    .clk(clk),
    .req(cache_req),
    .we(cache_we),
    .addr(pc),
    .data_in(inst_out),
    .data_out(cache_inst),
    .ready(cache_ready),
    .hit(cache_hit)
);

reg [1:0] cycle;

always @ (*) begin
    mem_req = 0;
    cache_req = 0;
    cache_we = 0;
    addr = pc;

    ready = cycle == DONE;

    if (~rst & en) begin
        case (cycle)
            QUERY_CACHE: cache_req = ~cache_ready;
            MEM_WAIT: mem_req = 1;
            UPDATE_CACHE: begin
                cache_we = 1;
                cache_req = ~cache_ready;
            end
            DONE: cache_we = 0;
        endcase
    end
end

always @ (posedge clk) begin
    if (~rst & en) begin
        case (cycle)
            QUERY_CACHE: begin
                cycle <= cache_ready ? (cache_hit ? DONE : MEM_WAIT) : QUERY_CACHE;
                inst_out <= cache_inst;
            end
            MEM_WAIT: begin
                cycle <= mem_ready ? UPDATE_CACHE : MEM_WAIT;
                inst_out <= data_in;
            end
            UPDATE_CACHE: cycle <= cache_ready ? UPDATE_CACHE : DONE;
        endcase
    end else begin
        cycle <= QUERY_CACHE;
        inst_out <= 0;
    end
end

endmodule
