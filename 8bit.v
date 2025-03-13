module eightbit
#(
    parameter OP_JMP = 2'b00,
    parameter OP_LOD = 2'b01,
    parameter OP_STR = 2'b10,
    parameter OP_ADD = 2'b11
)
(
    input rst,
    input clk,
    input [7:0] data_in,
    input mem_ready,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we,
    output reg mem_req
);

localparam STATE_IDLE = 2'b00;
localparam STATE_BUSY = 2'b10;
localparam STATE_COMPLETE = 2'b11;

reg [7:0] a, b, pc, inst;

reg fetch_en, fetch_ready;
reg fetch_mem_req, fetch_mem_ready;
reg [7:0] fetch_addr;
wire [1:0] fetch_state;

assign fetch_state = {fetch_en, fetch_ready};

fetch Fetch (
    .en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(pc),
    .mem_ready(fetch_mem_ready),
    .addr(fetch_addr),
    .inst_out(inst),
    .mem_req(fetch_mem_req),
    .ready(fetch_ready)
);

reg decode_ready, decode_en;
reg [7:0] decode_inst;
reg [5:0] decode_addr;
reg [1:0] decode_op;
reg decode_srcdst;
wire [1:0] decode_state;

assign decode_state = {decode_en, decode_ready};

decode Decode (
    .en(decode_en),
    .clk(clk),
    .inst(decode_inst),
    .op(decode_op),
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
reg exec_we, exec_mem_req, exec_mem_ready;
wire [1:0] exec_state;

assign exec_state = {exec_en, exec_ready};

exec #(
    .OP_LOD(OP_LOD),
    .OP_STR(OP_STR),
    .OP_ADD(OP_ADD)
) Execute (
    .en(exec_en),
    .clk(clk),
    .op(exec_op),
    .val1(exec_val1_in),
    .val2(exec_val2_in),
    .addr_in(exec_addr_in),
    .mem_ready(exec_mem_ready),
    .mem_data_in(data_in),
    .val_out(exec_val_out),
    .mem_addr(exec_addr),
    .mem_data_out(exec_data_out),
    .mem_req(exec_mem_req),
    .we(exec_we),
    .ready(exec_ready)
);

reg wb_srcdst, wb_ready, wb_en;
reg [1:0] wb_op;
wire [1:0] wb_state;

assign wb_state = {wb_en, wb_ready};

writeback #(
    .OP_LOD(OP_LOD),
    .OP_ADD(OP_ADD)
) Writeback (
    .en(wb_en),
    .clk(clk),
    .op(exec_op),
    .srcdst(wb_srcdst),
    .val(exec_val_out),
    .a(a),
    .b(b),
    .ready(wb_ready)
);

reg mem_fetch_busy;

function automatic stage_should_rst(input[1:0] this_stage_state, next_stage_state);
    stage_should_rst = this_stage_state == STATE_COMPLETE && next_stage_state == STATE_IDLE;
endfunction

always @ (posedge rst) begin
    pc = 8'h00;
    fetch_en = 0;
    decode_en = 0;
    exec_en = 0;
    wb_en = 0;
    mem_fetch_busy = 0;
end

always @ (posedge clk) begin
    if (~rst) begin
        if (stage_should_rst(fetch_state, decode_state)) begin
            decode_inst <= inst;
            decode_en <= 1;
            fetch_en <= 0;
            pc <= pc + 1;
        end
        if (fetch_state == STATE_IDLE)
            fetch_en <= 1;

        if (stage_should_rst(decode_state, exec_state) && wb_state == STATE_IDLE) begin
            exec_op <= decode_op;
            exec_addr_in <= decode_addr[4:0];
            exec_srcdst <= decode_srcdst;
            decode_en <= 0;

            case (decode_op)
                OP_JMP: begin
                    pc <= {2'b00, decode_addr};
                    fetch_en <= 0;
                    decode_en <= 0;
                    exec_en <= 0;
                end
                OP_LOD: exec_en <= 1;
                OP_STR: begin
                    exec_val1_in <= (decode_srcdst) ? b : a;
                    exec_en <= 1;
                end
                OP_ADD: begin
                    exec_val1_in <= a;
                    exec_val2_in <= b;
                    exec_en <= 1;
                end
            endcase
        end

        if (stage_should_rst(exec_state, wb_state)) begin
            exec_en <= 0;
                wb_op <= exec_op;
                wb_srcdst <= exec_srcdst;
                wb_en <= 1;
        end
        if (wb_state == STATE_COMPLETE)
            wb_en <= 0;

        // Memory request muxing
        if (exec_mem_req & ~mem_fetch_busy) begin
            mem_req <= 1;
            addr <= exec_addr;
            data_out <= exec_data_out;
            we <= exec_we;
            exec_mem_ready <= mem_ready;
        end else if (fetch_mem_req) begin
            mem_req <= 1;
            addr <= fetch_addr;
            mem_fetch_busy <= 1;
            we <= 0;
            fetch_mem_ready <= mem_ready;
        end else begin
            mem_req <= 0;
            mem_fetch_busy <= 0;
            we <= 0;
            fetch_mem_ready <= 0;
            exec_mem_ready <= 0;
        end
    end
end

endmodule
