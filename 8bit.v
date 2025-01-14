`default_nettype none

module eightbit(
    input clk,
    input [7:0] data_in,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we
);

reg [7:0] a, b, pc, inst;
reg fetch_en, fetch_ready;

fetch Fetch (
    .fetch_en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(pc),
    .addr(addr),
    .inst_out(inst)
);

initial begin
    pc = 8'h00;
    fetch_en = 1;
end

always @ (posedge fetch_ready) begin
    fetch_en = 0;
end

endmodule
