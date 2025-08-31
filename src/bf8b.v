module bf8b
#(
    parameter M_WIDTH = 32,
    parameter REG_CNT = 32,
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
    output [M_WIDTH-$clog2(M_WIDTH/8)-1:0] addr,
    output [M_WIDTH/8-1:0] wes
);

localparam INST_WIDTH = M_WIDTH;
localparam REG_ADDR_WIDTH = $clog2(REG_CNT);
localparam OP_WIDTH = 7;

localparam STATE_IDLE = 2'b00;
localparam STATE_BUSY = 2'b10;
localparam STATE_COMPLETE = 2'b11;
localparam STATE_RESETTING = 2'b01;

localparam MEM_ACC_8 = 2'b00;
localparam MEM_ACC_16 = 2'b01;
localparam MEM_ACC_32 = 2'b10;

wire [M_WIDTH-1:0] reg_file [REG_CNT-1:0];
wire [M_WIDTH*REG_CNT-1:0] packed_reg_file;

reg [M_WIDTH-1:0] pc, pc_next;

reg fetch_en, fetch_en_next;
reg [M_WIDTH-1:0] fetch_pc, fetch_pc_next;
wire [M_WIDTH-1:0] fetch_mem_data_in;
wire fetch_mem_ready;
wire fetch_mem_req;
wire fetch_ready;
wire [M_WIDTH-1:0] fetch_addr;
wire [INST_WIDTH-1:0] fetch_inst;
wire [1:0] fetch_state;

assign fetch_state = {fetch_en, fetch_ready};

fetch #(
    .M_WIDTH(M_WIDTH),
    .INST_WIDTH(INST_WIDTH)
) Fetch (
    .rst(rst),
    .en(fetch_en),
    .clk(clk),
    .data_in(fetch_mem_data_in),
    .pc(fetch_pc),
    .mem_ready(fetch_mem_ready),
    .addr(fetch_addr),
    .inst_out(fetch_inst),
    .mem_req(fetch_mem_req),
    .ready(fetch_ready)
);

reg decode_en, decode_en_next;
reg [INST_WIDTH-1:0] decode_inst, decode_inst_next;
reg [M_WIDTH-1:0] decode_pc, decode_pc_next;
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

reg exec_en, exec_en_next;
reg [OP_WIDTH-1:0] exec_op, exec_op_next;
reg [REG_ADDR_WIDTH-1:0] exec_wb_addr, exec_wb_addr_next;
reg [M_WIDTH-1:0] exec_pc_in, exec_pc_in_next;
reg [M_WIDTH-1:0] exec_rs1_in, exec_rs1_in_next;
reg [M_WIDTH-1:0] exec_rs2_in, exec_rs2_in_next;
reg [M_WIDTH-1:0] exec_imm_in, exec_imm_in_next;
reg [2:0] exec_funct3, exec_funct3_next;
reg [6:0] exec_funct7, exec_funct7_next;
wire [M_WIDTH-1:0] exec_data_out;
wire exec_ready;

wire [M_WIDTH-1:0] exec_mem_data_in;
wire [M_WIDTH-1:0] exec_mem_addr;
wire exec_mem_we, exec_mem_req;
wire exec_mem_ready;
wire [1:0] exec_mem_acc_width;

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
    .OP_INTEGER(OP_INTEGER),
    .MEM_ACC_8(MEM_ACC_8),
    .MEM_ACC_16(MEM_ACC_16),
    .MEM_ACC_32(MEM_ACC_32)
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
    .mem_data_in(exec_mem_data_in),
    .val_out(exec_val_out),
    .mem_addr(exec_mem_addr),
    .mem_data_out(exec_data_out),
    .mem_req(exec_mem_req),
    .mem_we(exec_mem_we),
    .mem_acc_width(exec_mem_acc_width),
    .pc_out(exec_pc_out),
    .flush_pipeline(exec_flush_pipeline),
    .ready(exec_ready)
);

reg wb_en, wb_en_next;
reg [6:0] wb_op, wb_op_next;
reg [M_WIDTH-1:0] wb_val, wb_val_next;
reg [REG_ADDR_WIDTH-1:0] wb_reg_addr, wb_reg_addr_next;
reg [2:0] wb_funct3, wb_funct3_next;
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
    .OP_INTEGER(OP_INTEGER),
    .MEM_ACC_8(MEM_ACC_8),
    .MEM_ACC_16(MEM_ACC_16),
    .MEM_ACC_32(MEM_ACC_32)
) Writeback (
    .en(wb_en),
    .clk(clk),
    .op(wb_op),
    .funct3(wb_funct3),
    .reg_addr(wb_reg_addr),
    .val(wb_val),
    .regs(packed_reg_file),
    .ready(wb_ready)
);

wire tx;
uart UART (
    .rst(rst),
    .clk(clk),
    .tx(tx)
);

mem_if #(
    .M_WIDTH(M_WIDTH),
    .CLIENT_CNT(2)
) MemoryInterface (
    .rst(rst),
    .clk(clk),
    .mem_data_in(data_in),
    .client_requests({exec_mem_req, fetch_mem_req}),
    .client_addrs_packed({exec_mem_addr, fetch_addr}),
    .client_wes({exec_mem_we, 1'b0}),
    .client_data_widths_packed({exec_mem_acc_width, MEM_ACC_32}),
    .client_data_outs_packed({exec_data_out, {M_WIDTH{1'b0}}}),
    .client_readies({exec_mem_ready, fetch_mem_ready}),
    .client_data_ins_packed({exec_mem_data_in, fetch_mem_data_in}),
    .mem_data_out(data_out),
    .mem_addr(addr),
    .mem_we_outs(wes)
);

genvar i;
generate
    for (i = 0; i < REG_CNT; i = i + 1) begin
        assign reg_file[i] = packed_reg_file[M_WIDTH*i +: M_WIDTH];
    end
endgenerate

reg fetch_should_start;
reg decode_should_start;
reg exec_should_start;
reg wb_should_start;
always @ (*) begin
    fetch_should_start = fetch_state == STATE_IDLE;

    decode_should_start =
        fetch_state == STATE_COMPLETE &&
        decode_state == STATE_IDLE;

    exec_should_start =
        decode_state == STATE_COMPLETE &&
        exec_state == STATE_IDLE;
    // Right now, writeback only takes one cycle to execute. This means that
    // even if writeback is busy, any dependency issue will have been resolved
    // by the time execute actually starts.

    wb_should_start =
    exec_state == STATE_COMPLETE &&
    (wb_state == STATE_IDLE || wb_state == STATE_RESETTING);
end

always @ (*) begin
    pc_next = pc;

    fetch_en_next = fetch_en;
    fetch_pc_next = fetch_pc;
    if (fetch_should_start) begin
        fetch_en_next = 1;
        fetch_pc_next = pc;
    end

    decode_en_next = decode_en;
    decode_inst_next = decode_inst;
    decode_pc_next = decode_pc;
    if (decode_should_start) begin
        decode_en_next = 1;
        decode_inst_next = fetch_inst;
        decode_pc_next = fetch_pc;
        fetch_en_next = 0;
        pc_next = pc + (INST_WIDTH / 8);
    end

    exec_en_next = exec_en;
    exec_op_next = exec_op;
    exec_pc_in_next = exec_pc_in;
    exec_wb_addr_next = exec_wb_addr;
    exec_rs1_in_next = exec_rs1_in;
    exec_rs2_in_next = exec_rs2_in;
    exec_imm_in_next = exec_imm_in;
    exec_funct3_next = exec_funct3;
    exec_funct7_next = exec_funct7;
    if (exec_should_start) begin
        exec_en_next = 1;
        exec_op_next = decode_op;
        exec_pc_in_next = decode_pc;
        exec_wb_addr_next = decode_rd;
        exec_rs1_in_next = reg_file[decode_rs1];
        exec_rs2_in_next = reg_file[decode_rs2];
        exec_imm_in_next = decode_imm;
        exec_funct3_next = decode_funct3;
        exec_funct7_next = decode_funct7;
        decode_en_next = 0;
    end

    wb_en_next = wb_en;
    wb_op_next = wb_op;
    wb_funct3_next = wb_funct3;
    wb_reg_addr_next = wb_reg_addr;
    wb_val_next = wb_val;
    if (wb_should_start) begin
        wb_op_next = exec_op;
        wb_funct3_next = exec_funct3;
        wb_reg_addr_next = exec_wb_addr;
        wb_val_next = exec_val_out;
        exec_en_next = 0;
        if (exec_flush_pipeline) begin
            pc_next = exec_pc_out;
            fetch_en_next = 0;
            decode_en_next = 0;
        end else
            wb_en_next = 1;
    end

    if (wb_state == STATE_COMPLETE)
        wb_en_next = 0;
end

always @ (posedge clk) begin
    if (rst) begin
        pc <= 0;

        fetch_en <= 0;
        fetch_pc <= 0;

        decode_en <= 0;
        decode_inst <= 0;
        decode_pc <= 0;

        exec_en <= 0;
        exec_op <= 0;
        exec_pc_in <= 0;
        exec_wb_addr <= 0;
        exec_rs1_in <= 0;
        exec_rs2_in <= 0;
        exec_imm_in <= 0;
        exec_funct3 <= 0;
        exec_funct7 <= 0;

        wb_en <= 0;
        wb_op <= 0;
        wb_funct3 <= 0;
        wb_reg_addr <= 0;
        wb_val <= 0;
    end else begin
        pc <= pc_next;

        fetch_en <= fetch_en_next;
        fetch_pc <= fetch_pc_next;

        decode_en <= decode_en_next;
        decode_inst <= decode_inst_next;
        decode_pc <= decode_pc_next;

        exec_en <= exec_en_next;
        exec_op <= exec_op_next;
        exec_pc_in <= exec_pc_in_next;
        exec_wb_addr <= exec_wb_addr_next;
        exec_rs1_in <= exec_rs1_in_next;
        exec_rs2_in <= exec_rs2_in_next;
        exec_imm_in <= exec_imm_in_next;
        exec_funct3 <= exec_funct3_next;
        exec_funct7 <= exec_funct7_next;

        wb_en <= wb_en_next;
        wb_op <= wb_op_next;
        wb_funct3 <= wb_funct3_next;
        wb_reg_addr <= wb_reg_addr_next;
        wb_val <= wb_val_next;
    end
end

endmodule

