module decode
#(
    parameter M_WIDTH = 8,
    parameter REG_ADDR_WIDTH = 4,
    parameter INST_WIDTH = 16,
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
    input [INST_WIDTH-1:0] inst,
    output reg [6:0] op,
    output reg [REG_ADDR_WIDTH-1:0] rd,
    output reg [REG_ADDR_WIDTH-1:0] rs1,
    output reg [REG_ADDR_WIDTH-1:0] rs2,
    output reg [M_WIDTH-1:0] imm,
    output reg [2:0] funct3,
    output reg [6:0] funct7,
    output reg ready
);

reg [M_WIDTH-1:0] imms, immi, immb, immu, immj;

always @ (*) begin
    op = inst[6:0];
    funct7 = inst[31:25];
    funct3 = inst[14:12];
    rd = inst[11:7];
    rs1 = inst[19:15];
    rs2 = inst[24:20];

    imms = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    immi = {{21{inst[31]}}, inst[30:20]};
    immb = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    immu = {inst[31:12], 12'b0};
    immj = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    case (opcode)
        OP_LUI, OP_AIUPC:
            imm = immu;
        OP_JAL:
            imm = immj;
        OP_JALR, OP_LOAD, OP_INTEGER_IMM:
            imm = immi;
        OP_BRANCH:
            imm = immb;
        default:
            imm = imms;
    endcase
end

always @ (posedge clk) begin
    ready <= en;
end

endmodule
