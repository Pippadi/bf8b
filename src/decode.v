module decode
#(
    parameter M_WIDTH = 8,
    parameter OP_WIDTH = 7,
    parameter REG_CNT = 32,
    parameter REG_ADDR_WIDTH = 5,
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
    input [M_WIDTH*REG_CNT-1:0] reg_file_packed,
    input [OP_WIDTH-1:0] op,
    input [M_WIDTH-1:0] pc,
    input [M_WIDTH-1:0] imm,
    input [REG_ADDR_WIDTH-1:0] rs1_addr,
    input [REG_ADDR_WIDTH-1:0] rs2_addr,
    output reg [M_WIDTH-1:0] immaddr,
    output reg [M_WIDTH-1:0] rs1,
    output reg [M_WIDTH-1:0] rs2,
    output reg ready
);

wire [M_WIDTH-1:0] rs1_temp = reg_file_packed[M_WIDTH*rs1_addr +: M_WIDTH];
wire [M_WIDTH-1:0] rs2_temp = reg_file_packed[M_WIDTH*rs2_addr +: M_WIDTH];

reg [M_WIDTH-1:0] aux_adder_in1, aux_adder_in2;
wire [M_WIDTH-1:0] aux_adder_out;

adder #(
    .M_WIDTH(M_WIDTH)
) AuxAdder (
    .cin(1'b0),
    .in1(aux_adder_in1),
    .in2(aux_adder_in2),
    .out(aux_adder_out)
);

always @ (*) begin
    case (op)
        OP_JALR, OP_LOAD, OP_STORE: begin
            aux_adder_in1 = rs1_temp;
            aux_adder_in2 = imm;
        end
        OP_JAL, OP_BRANCH: begin
            aux_adder_in1 = pc;
            aux_adder_in2 = imm;
        end
        default: begin
            aux_adder_in1 = 0;
            aux_adder_in2 = 0;
        end
    endcase
end

always @ (posedge clk) begin
    if (rst) begin
        rs1 <= 0;
        rs2 <= 0;
        immaddr <= 0;
        ready <= 0;
    end else begin
        if (en) begin
            rs1 <= rs1_temp;
            rs2 <= rs2_temp;
            immaddr <= (op == OP_JALR || op == OP_LOAD || op == OP_STORE ||
                op == OP_JAL || op == OP_BRANCH) ? aux_adder_out : imm;
        end
        ready <= en;
    end
end

endmodule
