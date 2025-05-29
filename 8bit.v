module eightbit
#(
    parameter M_WIDTH = 8,
    parameter REG_CNT = 16,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AIUPC = 7'b0010111,
    parameter OP_JAL = 7'b1101111,
    parameter OP_JALR = 7'b1100111,
    parameter OP_LOAD = 7'b0000011,
    parameter OP_STORE = 7'b0100011,
    parameter OP_BRANCH = 7'b1100011,
    parameter OP_INTEGER_IMM = 7'b0010011,
    parameter OP_INTEGER = 7'b0110011
)
(
    input rst,
    input clk,
    input [M_WIDTH-1:0] data_in,
    output [M_WIDTH-1:0] data_out,
    output [M_WIDTH-1:0] addr,
    output we
);

localparam INST_WIDTH = M_WIDTH;
localparam REG_ADDR_WIDTH = $clog2(REG_CNT);
localparam OP_WIDTH = 7;

localparam STATE_IDLE = 2'b00;
localparam STATE_BUSY = 2'b10;
localparam STATE_COMPLETE = 2'b11;
localparam STATE_RESETTING = 2'b01;

reg [M_WIDTH-1:0] reg_file [REG_CNT-1:0];
wire [M_WIDTH*REG_CNT-1:0] packed_reg_file;

reg [M_WIDTH-1:0] a, b;
reg [M_WIDTH-1:0] pc;

reg fetch_en;
reg [M_WIDTH-1:0] fetch_pc;
wire fetch_mem_ready;
wire fetch_mem_req;
wire fetch_ready;
wire [M_WIDTH-1:0] fetch_addr;
wire [INST_WIDTH-1:0] fetch_inst;
wire [1:0] fetch_state;

assign fetch_state = {fetch_en, fetch_ready};

wire fetch_busy;

fetch #(
    .M_WIDTH(M_WIDTH),
    .INST_WIDTH(INST_WIDTH)
) Fetch (
    .rst(rst),
    .en(fetch_en),
    .clk(clk),
    .data_in(data_in),
    .pc(fetch_pc),
    .mem_ready(fetch_mem_ready),
    .addr(fetch_addr),
    .inst_out(fetch_inst),
    .mem_req(fetch_mem_req),
    .busy(fetch_busy),
    .ready(fetch_ready)
);

reg start_decode;
reg decode_en;
reg [INST_WIDTH-1:0] decode_inst;
reg [M_WIDTH-1:0] decode_pc;
wire decode_ready;
wire [OP_WIDTH-1:0] decode_op;
wire [REG_ADDR_WIDTH-1:0] decode_rd, decode_rs1, decode_rs2;
wire [M_WIDTH-1:0] decode_imm;
wire [6:0] decode_funct7;
wire [2:0] decode_funct3;
wire [1:0] decode_state;

assign decode_state = {decode_en, decode_ready};

decode #(
    .M_WIDTH(M_WIDTH),
    .OP_WIDTH(OP_WIDTH),
    .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
    .INST_WIDTH(INST_WIDTH),
    .OP_LUI(OP_LUI),
    .OP_AIUPC(OP_AIUPC),
    .OP_JAL(OP_JAL),
    .OP_JALR(OP_JALR),
    .OP_LOAD(OP_LOAD),
    .OP_STORE(OP_STORE),
    .OP_BRANCH(OP_BRANCH),
    .OP_INTEGER_IMM(OP_INTEGER_IMM),
    .OP_INTEGER(OP_INTEGER)
) Decode (
    .en(decode_en),
    .clk(clk),
    .inst(decode_inst),
    .op(decode_op),
    .rd(decode_rd),
    .rs1(decode_rs1),
    .rs2(decode_rs2),
    .imm(decode_imm),
    .funct7(decode_funct7),
    .funct3(decode_funct3),
    .ready(decode_ready)
);

reg start_exec;
reg exec_en;
reg [OP_WIDTH-1:0] exec_op;
reg [REG_ADDR_WIDTH-1:0] exec_wb_addr;
reg [M_WIDTH-1:0] exec_pc_in;
reg [M_WIDTH-1:0] exec_rs1_in;
reg [M_WIDTH-1:0] exec_rs2_in;
reg [M_WIDTH-1:0] exec_imm_in;
reg [2:0] exec_funct3;
reg [6:0] exec_funct7;
wire [M_WIDTH-1:0] exec_data_out;
wire exec_ready;

wire [M_WIDTH-1:0] exec_mem_addr;
wire exec_mem_we, exec_mem_req;
wire exec_mem_ready;

wire [M_WIDTH-1:0] exec_pc_out;
wire exec_flush_pipeline;
wire [M_WIDTH-1:0] exec_val_out;
wire [1:0] exec_state;

assign exec_state = {exec_en, exec_ready};

exec #(
    .M_WIDTH(M_WIDTH),
    .OP_WIDTH(OP_WIDTH),
    .OP_LUI(OP_LUI),
    .OP_AIUPC(OP_AIUPC),
    .OP_JAL(OP_JAL),
    .OP_JALR(OP_JALR),
    .OP_LOAD(OP_LOAD),
    .OP_STORE(OP_STORE),
    .OP_BRANCH(OP_BRANCH),
    .OP_INTEGER_IMM(OP_INTEGER_IMM),
    .OP_INTEGER(OP_INTEGER)
) Execute (
    .en(exec_en),
    .clk(clk),
    .pc_in(exec_pc_in),
    .op(exec_op),
    .rs1(exec_rs1_in),
    .rs2(exec_rs2_in),
    .imm(exec_imm_in),
    .funct3(exec_funct3),
    .funct7(exec_funct7),
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
reg [M_WIDTH-1:0] wb_val;
reg [REG_ADDR_WIDTH-1:0] wb_reg_addr;
wire wb_ready;
wire [1:0] wb_state;

assign wb_state = {wb_en, wb_ready};

writeback #(
    .M_WIDTH(M_WIDTH),
    .REG_CNT(REG_CNT),
    .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
    .OP_LUI(OP_LUI),
    .OP_AIUPC(OP_AIUPC),
    .OP_JAL(OP_JAL),
    .OP_JALR(OP_JALR),
    .OP_LOAD(OP_LOAD),
    .OP_BRANCH(OP_BRANCH),
    .OP_INTEGER_IMM(OP_INTEGER_IMM),
    .OP_INTEGER(OP_INTEGER)
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
    .M_WIDTH(M_WIDTH),
    .CLIENT_CNT(2)
) MemoryInterface (
    .rst(rst),
    .clk(clk),
    .requests({exec_mem_req, fetch_mem_req}),
    .addrs({exec_mem_addr, fetch_addr}),
    .wes({exec_mem_we, 1'b0}),
    .data_outs({exec_data_out, {M_WIDTH{1'b0}}}),
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
    for (i = 0; i < REG_CNT; i = i + 1) begin
        reg_file[i] = packed_reg_file[M_WIDTH*i +: M_WIDTH];
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
        if (fetch_should_start(fetch_state) & ~fetch_busy) begin
            fetch_pc = pc;
            fetch_en = 1;
        end

        if (decode_should_start(fetch_state, decode_state)) begin
            decode_pc = fetch_pc;
            decode_inst = fetch_inst;
            fetch_en = 0;
            pc = pc + (INST_WIDTH / 8);
            decode_en = 1;
        end

        if (exec_should_start(decode_state, exec_state)) begin
            exec_op = decode_op;
            exec_pc_in = decode_pc;
            exec_wb_addr = decode_rd;
            exec_rs1_in = reg_file[decode_rs1];
            exec_rs2_in = reg_file[decode_rs2];
            exec_imm_in = decode_imm;
            exec_funct3 = decode_funct3;
            exec_funct7 = decode_funct7;
            exec_en = 1;
            decode_en = 0;
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
