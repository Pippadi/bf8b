module decode
#(
    parameter M_WIDTH = 8,
    parameter REG_ADDR_WIDTH = 4,
    parameter INST_WIDTH = 16,
    parameter OP_JMP = 4'b0000,
    parameter OP_LODI = 4'b0101
)
(
    input en,
    input clk,
    input [INST_WIDTH-1:0] inst,
    output reg [6:0] op,
    output reg [REG_ADDR_WIDTH-1:0] rd,
    output reg [REG_ADDR_WIDTH-1:0] rs1,
    output reg [REG_ADDR_WIDTH-1:0] rs2,
    output reg [M_WIDTH-1:0] imms,
    output reg [M_WIDTH-1:0] immi,
    output reg [M_WIDTH-1:0] immb,
    output reg [M_WIDTH-1:0] immu,
    output reg [M_WIDTH-1:0] immj,
    output reg [2:0] funct3,
    output reg [6:0] funct7,
    output reg ready
);

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
end

always @ (posedge clk) begin
    ready <= en;
end

endmodule
