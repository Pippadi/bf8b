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
reg decode_ready;

reg [7:0] decode_addr;
reg [7:0] fetch_addr;
reg [7:0] decode_pc;
reg [7:0] fetch_pc;

fetch Fetch (
    .fetch_en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(fetch_pc),
    .addr(fetch_addr),
    .inst_out(inst),
    .ready(fetch_ready)
);

decode_exec Exec (
    .en(fetch_ready),
    .clk(clk),
    .inst(inst),
    .data_in(data_in),
    .pc(decode_pc),
    .a(a),
    .b(b),
    .addr(decode_addr),
    .data_out(data_out),
    .we(we),
    .ready(decode_ready)
);

initial begin
    pc = 8'h00;
    fetch_pc = pc;
    fetch_en = 1;
end

always @ (posedge fetch_ready) begin
    fetch_en = 0;
end

always @ (posedge clk) begin
    if (fetch_en) begin
        addr <= fetch_addr;
        pc <= fetch_pc;
    end
    else begin
        addr <= decode_addr;
        pc <= decode_pc;
    end
end

endmodule
