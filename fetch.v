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
    .CELL_CNT(8)
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
reg hibyte;

always @ (posedge clk) begin
    if (~rst & en) begin
        case (cycle)
            0: begin
                if (cache_hit) begin
                    inst_out <= cache_inst;
                    cycle <= 2;
                end else begin
                    addr <= (hibyte) ? pc : pc + 1;
                    mem_req <= 1;
                    cycle <= 1;
                end
            end
            1: begin
                if (mem_ready) begin
                    mem_req <= 0;
                    if (hibyte) begin
                        inst_out[M_WIDTH+:M_WIDTH] <= data_in;
                        cycle <= 0;
                        hibyte <= 0;
                    end else begin
                        inst_out[0+:M_WIDTH] <= data_in;
                        cycle <= 2;
                    end
                end
            end
            2: begin
                cycle <= 3;
                ready <= 1;
                cache_we <= 1;
            end
            3: cache_we <= 0;
        endcase
    end

    else begin
        ready <= 0;
        mem_req <= 0;
        cache_we <= 0;
        cycle <= 0;
        hibyte <= 1;
    end
end

endmodule
