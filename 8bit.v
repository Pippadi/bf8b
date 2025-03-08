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
    .en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(pc),
    .addr(fetch_addr),
    .inst_out(inst),
    .ready(fetch_ready)
);

reg decode_ready, decode_en;
reg [7:0] decode_inst;
reg [5:0] decode_addr;
reg [1:0] decode_inst_type;
reg decode_srcdst;

decode Decode (
    .en(decode_en),
    .clk(clk),
    .inst(decode_inst),
    .inst_type(decode_inst_type),
    .addr(decode_addr),
    .srcdst(decode_srcdst),
    .ready(decode_ready)
);

reg exec_en;
reg exec_ready;
reg [1:0] exec_op;
reg [4:0] exec_addr_in;
reg [7:0] exec_val1_in;
reg [7:0] exec_val2_in;
reg [7:0] exec_val_out;
reg [7:0] exec_addr;
reg [7:0] exec_data_out;
reg exec_srcdst;
reg exec_we;

exec Execute (
    .en(exec_en),
    .clk(clk),
    .op(exec_op),
    .val1(exec_val1_in),
    .val2(exec_val1_in),
    .addr_in(exec_addr_in),
    .mem_data_in(data_in),
    .val_out(exec_val_out),
    .mem_addr(exec_addr),
    .mem_data_out(exec_data_out),
    .we(exec_we),
    .ready(exec_ready)
);

reg wb_srcdst, wb_ready, wb_en;
reg [1:0] wb_op;

writeback Writeback(
    .en(wb_en),
    .clk(clk),
    .op(exec_op),
    .srcdst(wb_srcdst),
    .val(exec_val_out),
    .a(a),
    .b(b),
    .ready(wb_ready)
);

initial begin
    pc = 8'h00;
    fetch_en = 1;
    decode_en = 0;
    exec_en = 0;
    wb_en = 0;
end

always @ (posedge wb_ready) begin
    wb_en <= 0;
end

always @ (posedge clk) begin
    if (fetch_ready & ~decode_en) begin
        decode_inst <= inst;
        decode_en <= 1;
        fetch_en <= 0;
        pc <= pc + 1;
    end
    if (~fetch_ready & ~(exec_en & ~exec_ready)) begin
        fetch_en <= 1;
    end
    if (fetch_en) begin
        addr <= fetch_addr;
    end

    if (decode_ready & ~exec_en & ~(fetch_en & ~fetch_ready)) begin
        exec_op <= decode_inst_type;
        exec_addr_in <= decode_addr[4:0];
        exec_srcdst <= decode_srcdst;
        decode_en <= 0;

        case (decode_inst_type)
            2'b00: begin
                pc <= {2'b00, decode_addr};
                fetch_en <= 0;
                decode_en <= 0;
                exec_en <= 0;
            end
            2'b01: begin
                exec_en <= 1;
            end
            2'b10: begin
                exec_val1_in <= (decode_srcdst) ? a : b;
                exec_en <= 1;
            end
            2'b11: begin
                exec_en <= 1;
            end
        endcase
    end
    if (exec_en) begin
        addr <= exec_addr;
        we <= exec_we;
        data_out <= exec_data_out;
    end

    if (exec_ready & ~wb_en) begin
        wb_op <= exec_op;
        wb_srcdst <= exec_srcdst;
        wb_en <= 1;
        exec_en <= 0;
    end
end

endmodule
