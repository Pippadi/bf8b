module instruction_decode
#(
    parameter M_WIDTH = 32,
    parameter OP_WIDTH = 7,
    parameter REG_ADDR_WIDTH = 5,
    parameter INST_WIDTH = 32,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AUIPC = 7'b0010111,
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
    input en,
    input [INST_WIDTH-1:0] inst,
    output reg [OP_WIDTH-1:0] op,
    output reg [REG_ADDR_WIDTH-1:0] rd_addr,
    output reg [M_WIDTH-1:0] imm,
    output reg [2:0] funct3,
    output reg [6:0] funct7,
    output reg [REG_ADDR_WIDTH-1:0] rs1_addr,
    output reg [REG_ADDR_WIDTH-1:0] rs2_addr,
    output reg ready
);

reg [M_WIDTH-1:0] imms, immi, immb, immu, immj, imm_temp;
reg [OP_WIDTH-1:0] op_temp;

always @ (*) begin
    op_temp = inst[6:0];
    imms = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    immi = {{21{inst[31]}}, inst[30:20]};
    immb = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    immu = {inst[31:12], 12'b0};
    immj = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    case (op_temp)
        OP_LUI, OP_AUIPC:
            imm_temp = immu;
        OP_JAL:
            imm_temp = immj;
        OP_JALR, OP_LOAD, OP_INTEGER_IMM:
            imm_temp = immi;
        OP_BRANCH:
            imm_temp = immb;
        default:
            imm_temp = imms;
    endcase
end

always @ (posedge clk) begin
    if (rst) begin
        ready <= 0;
        op <= 0;
        funct7 <= 0;
        funct3 <= 0;
        rd_addr <= 0;
        rs1_addr <= 0;
        rs2_addr <= 0;
        imm <= 0;
    end else begin
        ready <= en;
        if (en) begin
            op <= op_temp;
            funct7 <= inst[31:25];
            funct3 <= inst[14:12];
            rd_addr <= inst[11:7];
            rs1_addr <= inst[19:15];
            rs2_addr <= inst[24:20];
            imm <= imm_temp;
        end
    end
end

endmodule
