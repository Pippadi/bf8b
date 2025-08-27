module fetch
#(
    M_WIDTH = 8,
    INST_WIDTH = 16
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

reg cache_we;
wire cache_hit;
wire [INST_WIDTH-1:0] cache_inst;

cache #(
    .DATA_WIDTH(INST_WIDTH),
    .ADDR_WIDTH(M_WIDTH),
    .CELL_CNT(32)
) ICache (
    .rst(rst),
    .clk(clk),
    .we(cache_we),
    .addr(pc),
    .data_in(inst_out),
    .data_out(cache_inst),
    .hit(cache_hit)
);

reg [1:0] cycle;

always @ (*) begin
    mem_req = 0;
    cache_we = 0;
    addr = pc;

    ready = cycle == 3;

    // Might cause problems if the memory interface decides to put garbage on
    // the data in line. Not robust, but good enough for now.
    inst_out = cache_hit ? cache_inst : data_in;

    if (~rst & en) begin
        case (cycle)
            1: mem_req = 1;
            2: cache_we = 1;
            3: cache_we = 0;
        endcase
    end
end

always @ (posedge clk) begin
    if (~rst & en) begin
        case (cycle)
            0: cycle <= cache_hit ? 2 : 1;
            1: cycle <= mem_ready ? 2 : 1;
            2: cycle <= 3;
        endcase
    end

    else
        cycle <= 0;
end

endmodule
