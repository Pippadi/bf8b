module decode
#(
    parameter M_WIDTH = 8,
    parameter INST_WIDTH = 16,
    parameter OP_JMP = 4'b0000,
    parameter OP_LODI = 4'b0101
)
(
    input en,
    input clk,
    input [INST_WIDTH-1:0] inst,
    output reg [3:0] op,
    output reg [3:0] reg0,
    output reg [3:0] reg1,
    output reg [3:0] reg2,
    output reg [M_WIDTH-1:0] imm,
    output reg ready
);

always @ (*) begin
    op = inst[15:12];
    reg0 = inst[11:8];
    reg1 = inst[7:4];
    reg2 = inst[3:0];
    if (inst[15:12] == OP_LODI || inst[15:12] == OP_JMP)
        imm = inst[7:0];
    else
        imm = { {5{ inst[3] }},  inst[2:0] };
end

always @ (posedge clk) begin
    ready <= en;
end

endmodule
