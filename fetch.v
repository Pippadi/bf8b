module fetch(
    input rst,
    input en,
    input clk,
    input [7:0] data_in,
    input [7:0] pc,
    input mem_ready,
    output reg [7:0] addr,
    output reg [15:0] inst_out,
    output reg mem_req,
    output reg ready
);

reg cache_we;
wire cache_hit;
wire [15:0] cache_inst;

cache #(
    .DATA_WIDTH(16),
    .ADDR_WIDTH(8),
    .CELL_CNT(8)
) ICache (
    .rst(rst),
    .clk(clk),
    .we(cache_we),
    .addr(pc),
    .data(cache_inst),
    .hit(cache_hit)
);

assign cache_inst = (cache_we) ? inst_out : 16'hzzzz;

reg [1:0] cycle;
reg hibyte;

always @ (posedge clk or posedge en) begin
    if (~rst & en) begin
        case (cycle)
            2'b00: begin
                addr <= (hibyte) ? pc : pc + 1;
                cycle <= cycle + 1;
                mem_req <= 1;
            end
            2'b01: begin
                if (cache_hit) begin
                    inst_out <= cache_inst;
                    cycle <= 2'b11;
                    mem_req <= 0;
                end
                if (mem_ready) begin
                    mem_req <= 0;
                    if (hibyte) begin
                        inst_out[15:8] <= data_in;
                        cycle <= 2'b00;
                        hibyte <= 0;
                    end
                    else begin
                        inst_out[7:0] <= data_in;
                        cycle <= cycle + 1;
                    end
                end
            end
            2'b10: begin
                cycle <= cycle + 1;
                cache_we <= 1;
            end
            2'b11: begin
                ready <= 1;
                cache_we <= 0;
            end
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
