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

fetch Fetch (
    .fetch_en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(pc),
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

reg exec_en;
reg exec_ready;
reg [7:0] exec_val1_in;
reg [7:0] exec_val2_in;
reg [7:0] exec_val_out;
reg [7:0] exec_addr;
reg [7:0] exec_data_out;
reg exec_we;

exec Execute (
    .en(exec_en),
    .clk(clk),
    .op(decode_inst_type),
    .val1(exec_val1_in),
    .val2(exec_val1_in),
    .addr_in(decode_addr[4:0]),
    .mem_data_in(data_in),
    .val_out(exec_val_out),
    .mem_addr(exec_addr),
    .mem_data_out(exec_data_out),
    .we(exec_we),
    .ready(exec_ready)
);

initial begin
    pc = 8'h00;
    fetch_en = 1;
    exec_en = 0;
end

always @ (posedge fetch_ready) begin
    fetch_en = 0;
end

always @ (posedge clk) begin
    if (fetch_en) begin
        addr <= fetch_addr;
    end

    if (decode_ready & ~exec_en & ~fetch_en) begin
        case (decode_inst_type)
            2'b00: begin
                pc <= {2'b00, decode_addr};
                fetch_en <= 1;
                // Flush pipeline
            end
            2'b01: begin
                exec_en <= 1;
            end
            2'b10: begin
                exec_val1_in <= (decode_srcdst) ? a : b;
                exec_en <= 1;
            end
            2'b11: begin
            end
        endcase
    end

    if (exec_en) begin
        addr <= exec_addr;
        we <= exec_we;
        data_out <= exec_data_out;
    end
end

endmodule
