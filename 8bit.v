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
reg [7:0] fetch_addr;
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

reg decode_ready;
reg [5:0] decode_addr;
reg [1:0] decode_inst_type;
reg decode_srcdst;

decode Decode (
    .en(fetch_ready),
    .clk(clk),
    .inst(inst),
    .inst_type(decode_inst_type),
    .addr(decode_addr),
    .srcdst(decode_srcdst),
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

    if (decode_ready) begin
        case (decode_inst_type)
            2'b00: begin
                pc <= {2'b00, decode_addr};
                fetch_en <= 1;
            end
            2'b01: begin
            end
            2'b10: begin
            end
            2'b11: begin
            end
        endcase
    end
end

endmodule
