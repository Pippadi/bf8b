module writeback
#(
    parameter M_WIDTH = 8,
    parameter REG_CNT = 16,
    parameter REG_ADDR_WIDTH = 4,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AUIPC = 7'b0010111,
    parameter OP_JAL = 7'b1101111,
    parameter OP_JALR = 7'b1100111,
    parameter OP_LOAD = 7'b0000011,
    parameter OP_BRANCH = 7'b1100011,
    parameter OP_INTEGER_IMM = 7'b0010011,
    parameter OP_INTEGER = 7'b0110011,
    parameter MEM_ACC_8 = 2'b00,
    parameter MEM_ACC_16 = 2'b01,
    parameter MEM_ACC_32 = 2'b10
)
(
    input rst,
    input clk,
    input en,
    input [6:0] op,
    input [2:0] funct3,
    input [REG_ADDR_WIDTH-1:0] reg_addr,
    input [M_WIDTH-1:0] val,
    output wire [M_WIDTH*REG_CNT-1:0] regs,
    output reg ready
);

reg [M_WIDTH-1:0] reg_file [0:REG_CNT-1];

// Pack the unpacked register file
genvar i;
generate
    for (i = 0; i < REG_CNT; i = i + 1) begin
        assign regs[M_WIDTH*i +: M_WIDTH] = reg_file[i];
    end
endgenerate

wire needs_writeback;
assign needs_writeback =
    (op == OP_LUI) ||
    (op == OP_AUIPC) ||
    (op == OP_JAL) ||
    (op == OP_JALR) ||
    (op == OP_INTEGER_IMM) ||
    (op == OP_INTEGER) ||
    (op == OP_LOAD);

integer j;
always @ (posedge clk) begin
    reg_file[0] <= 0;
    if (rst) begin
        for (j = 1; j < REG_CNT; j = j + 1)
            reg_file[j] <= 0;
        ready <= 0;
    end else begin
        if (en && needs_writeback && reg_addr != 0) begin
            // funct3[2] controls sign extension for loads
            casez ({op, funct3[1:0]})
                {OP_LUI, 2'b??}: reg_file[reg_addr][31:12] <= val[31:12];
                {OP_AUIPC, 2'b??}: reg_file[reg_addr][31:12] <= val[31:12];
                {OP_LOAD, MEM_ACC_8}: reg_file[reg_addr] <= {{24{~funct3[2] & val[7]}}, val[7:0]};
                {OP_LOAD, MEM_ACC_16}: reg_file[reg_addr] <= {{16{~funct3[2] & val[15]}}, val[15:0]};
                default: reg_file[reg_addr] <= val;
            endcase
        end
        ready <= en;
    end
end

endmodule
