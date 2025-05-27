module writeback
#(
    parameter M_WIDTH = 8,
    parameter REG_CNT = 16,
    parameter REG_ADDR_WIDTH = 4,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AIUPC = 7'b0010111,
    parameter OP_JAL = 7'b1101111,
    parameter OP_JALR = 7'b1100111,
    parameter OP_LOAD = 7'b0000011,
    parameter OP_BRANCH = 7'b1100011,
    parameter OP_INTEGER_IMM = 7'b0010011,
    parameter OP_INTEGER = 7'b0110011
)
(
    input en,
    input clk,
    input [3:0] op,
    input [REG_ADDR_WIDTH-1:0] reg_addr,
    input [M_WIDTH-1:0] val,
    output reg [M_WIDTH*REG_CNT-1:0] regs,
    output reg ready
);

reg [M_WIDTH-1:0] reg_file [0:REG_CNT-1];

// Pack the unpacked register file
integer i;
always @ (*) begin
    for (i = 0; i < REG_CNT; i = i + 1) begin
        regs[M_WIDTH*i +: M_WIDTH] = reg_file[i];
    end
end

function automatic needs_writeback (input [3:0] op);
    needs_writeback =
        (op == OP_LUI) ||
        (op == OP_AIUPC) ||
        (op == OP_JAL) ||
        (op == OP_JALR) ||
        (op == OP_INTEGER_IMM) ||
        (op == OP_INTEGER) ||
        (op == OP_LOAD);
endfunction

always @ (posedge clk) begin
    if (en && needs_writeback(op) && reg_addr != 0)
        reg_file[reg_addr] <= val;
    ready <= en;
    reg_file[0] = 0;
end

endmodule
