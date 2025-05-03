module eightbit
#(
    parameter OP_JMP = 4'b0000,
    parameter OP_LOD = 4'b0001,
    parameter OP_STR = 4'b0010,
    parameter OP_ADD = 4'b0011,
    parameter OP_ADDI = 4'b0100,
    parameter OP_LODI = 4'b0101,
    parameter OP_NAND = 4'b0110,
    parameter OP_JEQZ = 4'b0111
)
(
    input rst,
    input clk,
    input [7:0] data_in,
    output [7:0] data_out,
    output [7:0] addr,
    output we
);

localparam STATE_IDLE = 2'b00;
localparam STATE_BUSY = 2'b10;
localparam STATE_COMPLETE = 2'b11;
localparam STATE_RESETTING = 2'b01;

reg [7:0] reg_file [15:0];
wire [8*16-1:0] packed_reg_file;

reg [7:0] a, b;
reg [7:0] pc;

reg fetch_en;
reg [7:0] fetch_pc;
wire fetch_mem_ready;
wire fetch_mem_req;
wire fetch_ready;
wire [7:0] fetch_addr;
wire [15:0] fetch_inst;
wire [1:0] fetch_state;

assign fetch_state = {fetch_en, fetch_ready};

fetch Fetch (
    .rst(rst),
    .en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(fetch_pc),
    .mem_ready(fetch_mem_ready),
    .addr(fetch_addr),
    .inst_out(fetch_inst),
    .mem_req(fetch_mem_req),
    .ready(fetch_ready)
);

reg start_decode;
reg decode_en;
reg [15:0] decode_inst;
wire decode_ready;
wire [7:0] decode_imm;
wire [3:0] decode_op;
wire [3:0] decode_reg0, decode_reg1, decode_reg2;
wire [1:0] decode_state;

assign decode_state = {decode_en, decode_ready};

decode #(
    .OP_JMP(OP_JMP),
    .OP_LODI(OP_LODI)
) Decode (
    .en(decode_en),
    .clk(clk),
    .inst(decode_inst),
    .op(decode_op),
    .imm(decode_imm),
    .reg0(decode_reg0),
    .reg1(decode_reg1),
    .reg2(decode_reg2),
    .ready(decode_ready)
);

reg start_exec;
reg exec_en;
reg [3:0] exec_op;
reg [3:0] exec_wb_addr;
reg [7:0] exec_reg0_in;
reg [7:0] exec_reg1_in;
reg [7:0] exec_imm_in;
wire [7:0] exec_data_out;
wire exec_ready;

wire [7:0] exec_mem_addr;
wire exec_mem_we, exec_mem_req;
wire exec_mem_ready;

wire [7:0] exec_pc_out;
wire exec_flush_pipeline;
wire [7:0] exec_val_out;
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
    .reg0(exec_reg0_in),
    .reg1(exec_reg1_in),
    .imm(exec_imm_in),
    .mem_ready(exec_mem_ready),
    .mem_data_in(data_in),
    .val_out(exec_val_out),
    .mem_addr(exec_mem_addr),
    .mem_data_out(exec_data_out),
    .mem_req(exec_mem_req),
    .mem_we(exec_mem_we),
    .pc_out(exec_pc_out),
    .flush_pipeline(exec_flush_pipeline),
    .ready(exec_ready)
);

reg start_wb;
reg wb_en;
reg [3:0] wb_op;
reg [7:0] wb_val;
reg [3:0] wb_reg_addr;
wire wb_ready;
wire [1:0] wb_state;

assign wb_state = {wb_en, wb_ready};

writeback #(
    .OP_LOD(OP_LOD),
    .OP_ADD(OP_ADD)
) Writeback (
    .en(wb_en),
    .clk(clk),
    .op(wb_op),
    .reg_addr(wb_reg_addr),
    .val(wb_val),
    .regs(packed_reg_file),
    .ready(wb_ready)
);

mem_if #(
    .CLIENT_CNT(2)
) MemoryInterface (
    .rst(rst),
    .clk(clk),
    .requests({exec_mem_req, fetch_mem_req}),
    .addrs({exec_mem_addr, fetch_addr}),
    .wes({exec_mem_we, 1'b0}),
    .data_outs({exec_data_out, 8'b0}),
    .readies({exec_mem_ready, fetch_mem_ready}),
    .data_out(data_out),
    .addr(addr),
    .we(we)
);

function automatic fetch_should_start(input [1:0] fetch_state);
    fetch_should_start = fetch_state == STATE_IDLE;
endfunction

function automatic decode_should_start(input [1:0] fetch_state, decode_state);
    decode_should_start =
        fetch_state == STATE_COMPLETE &&
        (decode_state == STATE_IDLE);
endfunction

function automatic exec_should_start(input [1:0] decode_state, exec_state);
    exec_should_start =
        decode_state == STATE_COMPLETE &&
        (exec_state == STATE_IDLE || exec_state == STATE_RESETTING);
    // Right now, writeback only takes one cycle to execute. This means that
    // even if writeback is busy, any dependency issue will have been resolved
    // by the time execute actually starts (the cycle after the calling of
    // this function).
endfunction

function automatic wb_should_start(input [1:0] exec_state, wb_state);
    wb_should_start =
        exec_state == STATE_COMPLETE &&
        (wb_state == STATE_IDLE || wb_state == STATE_RESETTING);
endfunction

// Pack the register file to satisfy more strict Verilog rules
integer i;
always @ (*) begin
    for (i = 0; i < 16; i = i + 1) begin
        reg_file[i] = packed_reg_file[8*i +: 8];
    end
end

always @ (*) begin
    if (rst) begin
        pc = 0;
        fetch_en = 0;
        decode_en = 0;
        exec_en = 0;
        wb_en = 0;
        start_decode = 0;
        start_exec = 0;
        start_wb = 0;
    end

    else begin
        if (fetch_should_start(fetch_state)) begin
            fetch_pc = pc;
            fetch_en = 1;
        end

        if (decode_should_start(fetch_state, decode_state)) begin
            decode_inst = fetch_inst;
            fetch_en = 0;
            pc = pc + 2;
            decode_en = 1;
        end

        if (exec_should_start(decode_state, exec_state)) begin
            exec_op = decode_op;
            exec_wb_addr = decode_reg0;
            exec_imm_in = decode_imm;
            exec_en = 1;
            decode_en = 0;

            if (decode_op == OP_STR || decode_op == OP_JMP || decode_op == OP_JEQZ) begin
                exec_reg0_in = reg_file[decode_reg0];
                exec_reg1_in = reg_file[decode_reg1];
            end else begin
                exec_reg0_in = reg_file[decode_reg1];
                exec_reg1_in = reg_file[decode_reg2];
            end
        end

        if (wb_should_start(exec_state, wb_state)) begin
            wb_op = exec_op;
            wb_reg_addr = exec_wb_addr;
            wb_val = exec_val_out;
            exec_en = 0;
            if (exec_flush_pipeline) begin
                pc = exec_pc_out;
                fetch_en = 0;
                decode_en = 0;
            end else
                wb_en = 1;
        end

        if (wb_state == STATE_COMPLETE) begin
            wb_en = 0;
        end
    end
end

endmodule
