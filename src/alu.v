module alu
#(
    parameter M_WIDTH = 8,
    parameter F3_ADD = 3'b000,
    parameter F3_SLL = 3'b001,
    parameter F3_SLT = 3'b010,
    parameter F3_SLTU = 3'b011,
    parameter F3_XOR = 3'b100,
    parameter F3_SR = 3'b101,
    parameter F3_OR = 3'b110,
    parameter F3_AND = 3'b111
)
(
    input [2:0] funct3,
    input modifier,
    input [M_WIDTH-1:0] in1,
    input [M_WIDTH-1:0] in2,
    output reg [M_WIDTH-1:0] out
);

always @ (*) begin
    case (funct3)
        F3_ADD: out = in1 + (in2 ^ {M_WIDTH{modifier}}) + modifier;
        F3_SLL: out = in1 << in2;
        F3_SLT: out = in1 < in2;
        F3_SLTU: out = {1'b0, in1} < {1'b0, in2};
        F3_XOR: out = in1 ^ in2;
        F3_SR: out = modifier ? (in1 >>> in2) : (in1 >> in2);
        F3_OR: out = in1 | in2;
        F3_AND: out = in1 & in2;
    endcase
end

endmodule
