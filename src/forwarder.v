module forwarder
#(
    parameter M_WIDTH = 32,
    parameter OP_WIDTH = 7,
    parameter REG_ADDR_WIDTH = 5,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AUIPC = 7'b0010111,
    parameter OP_JAL = 7'b1101111,
    parameter OP_JALR = 7'b1100111,
    parameter OP_LOAD = 7'b0000011,
    parameter OP_STORE = 7'b0100011,
    parameter OP_BRANCH = 7'b1100011,
    parameter OP_INTEGER_IMM = 7'b0010011,
    parameter OP_INTEGER = 7'b0110011,
    parameter STATE_BUSY = 2'b10,
    parameter STATE_COMPLETE = 2'b11
)
(
    input [REG_ADDR_WIDTH-1:0] decode_rs1_addr,
    input [REG_ADDR_WIDTH-1:0] decode_rs2_addr,
    input [M_WIDTH-1:0] decode_rs1_out,
    input [M_WIDTH-1:0] decode_rs2_out,
    input [M_WIDTH-1:0] true_rs1,
    input [M_WIDTH-1:0] true_rs2,
    input [REG_ADDR_WIDTH-1:0] exec_rs1_addr,
    input [REG_ADDR_WIDTH-1:0] exec_rs2_addr,
    input [REG_ADDR_WIDTH-1:0] exec_rd_addr,
    input [REG_ADDR_WIDTH-1:0] wb_rd_addr,
    input [M_WIDTH-1:0] exec_val_out,
    input [OP_WIDTH-1:0] exec_op,
    input [1:0] exec_state,
    input [1:0] wb_state,
    output reg [M_WIDTH-1:0] exec_rs1,
    output reg [M_WIDTH-1:0] exec_rs2,
    output reg [M_WIDTH-1:0] decode_rs1_in,
    output reg [M_WIDTH-1:0] decode_rs2_in,
    output wire needs_writeback,
    output reg stall_decode
);

assign needs_writeback =
    (exec_op == OP_LUI) ||
    (exec_op == OP_AUIPC) ||
    (exec_op == OP_JAL) ||
    (exec_op == OP_JALR) ||
    (exec_op == OP_INTEGER_IMM) ||
    (exec_op == OP_INTEGER) ||
    (exec_op == OP_LOAD);

wire decode_exec_dependency = needs_writeback && (decode_rs1_addr == exec_rd_addr || decode_rs2_addr == exec_rd_addr) && exec_rd_addr != 0;
wire decode_wb_dependency = wb_state == STATE_BUSY && (decode_rs1_addr == wb_rd_addr || decode_rs2_addr == wb_rd_addr) && wb_rd_addr != 0;

always @ (*) begin
    stall_decode = decode_exec_dependency && exec_state == STATE_BUSY || decode_wb_dependency;
    exec_rs1 = decode_rs1_out;
    exec_rs2 = decode_rs2_out;

    if (needs_writeback) begin
        exec_rs1 = (exec_rs1_addr == exec_rd_addr) ? exec_val_out : decode_rs1_out;
        exec_rs2 = (exec_rs2_addr == exec_rd_addr) ? exec_val_out : decode_rs2_out;
    end

    decode_rs1_in = decode_exec_dependency ? exec_val_out : true_rs1;
    decode_rs2_in = decode_exec_dependency ? exec_val_out : true_rs2;
end

endmodule
