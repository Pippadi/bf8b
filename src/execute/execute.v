module exec
#(
    parameter M_WIDTH = 8,
    parameter OP_WIDTH = 7,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AIUPC = 7'b0010111,
    parameter OP_JAL = 7'b1101111,
    parameter OP_JALR = 7'b1100111,
    parameter OP_LOAD = 7'b0000011,
    parameter OP_STORE = 7'b0100011,
    parameter OP_BRANCH = 7'b1100011,
    parameter OP_INTEGER_IMM = 7'b0010011,
    parameter OP_INTEGER = 7'b0110011,
    parameter F3_ADD = 3'b000,
    parameter F3_SLL = 3'b001,
    parameter F3_SLT = 3'b010,
    parameter F3_SLTU = 3'b011,
    parameter F3_XOR = 3'b100,
    parameter F3_SR = 3'b101,
    parameter F3_OR = 3'b110,
    parameter F3_AND = 3'b111,
    parameter F3_EQ = 3'b000,
    parameter F3_NE = 3'b001,
    parameter F3_LT = 3'b100,
    parameter F3_GE = 3'b101,
    parameter F3_LTU = 3'b110,
    parameter F3_GEU = 3'b111,
    parameter MEM_ACC_8 = 2'b00,
    parameter MEM_ACC_16 = 2'b01,
    parameter MEM_ACC_32 = 2'b10
)
(
    input en,
    input clk,
    input [OP_WIDTH-1:0] op,
    input [6:0] funct7,
    input [2:0] funct3,
    input [M_WIDTH-1:0] pc_in,
    input [M_WIDTH-1:0] rs1,
    input [M_WIDTH-1:0] rs2,
    input [M_WIDTH-1:0] imm,
    input [M_WIDTH-1:0] mem_data_in,
    input mem_ready,
    output reg [M_WIDTH-1:0] pc_out,
    output reg [M_WIDTH-1:0] val_out,
    output reg [M_WIDTH-1:0] mem_addr,
    output reg [M_WIDTH-1:0] mem_data_out,
    output reg [1:0] mem_acc_width,
    output reg mem_req,
    output reg mem_we,
    output reg flush_pipeline,
    output reg ready
);

reg [M_WIDTH-1:0] alu_in1, alu_in2;
reg [2:0] alu_funct3;
reg alu_modifier;
wire [M_WIDTH-1:0] alu_out;

alu #(
    .M_WIDTH(M_WIDTH),
    .F3_ADD(F3_ADD),
    .F3_SLL(F3_SLL),
    .F3_SLT(F3_SLT),
    .F3_SLTU(F3_SLTU),
    .F3_XOR(F3_XOR),
    .F3_SR(F3_SR),
    .F3_OR(F3_OR),
    .F3_AND(F3_AND)
) ALU (
    .funct3(alu_funct3),
    .in1(alu_in1),
    .in2(alu_in2),
    .modifier(alu_modifier),
    .out(alu_out)
);

reg [M_WIDTH-1:0] aux_adder_in1;
reg [M_WIDTH-1:0] aux_adder_in2;
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
    flush_pipeline = 0;
    alu_modifier = 0;
    val_out = alu_out;
    alu_in1 = 0;
    alu_in2 = 0;
    alu_funct3 = F3_ADD;
    mem_req = 0;
    mem_addr = 0;
    mem_we = 0;
    mem_data_out = 0;
    mem_acc_width = funct3[1:0];
    aux_adder_in1 = imm;
    aux_adder_in2 = rs1;

    if (en) begin
        if (op == OP_LOAD || op == OP_STORE) begin
            case (cycle)
                0, 1: begin
                    mem_addr = aux_adder_out;
                    mem_we = op == OP_STORE;
                    mem_data_out = rs2;
                    mem_req = 1;
                end

                2: begin
                    mem_req = 0;
                    val_out = mem_data_in;
                end
            endcase
        end
        else begin
            case (op)
                OP_LUI: begin
                    alu_in1 = imm;
                    alu_in2 = 0;
                end
                OP_AIUPC: begin
                    alu_in1 = imm;
                    alu_in2 = pc_in;
                end
                OP_JAL: begin
                    alu_in1 = 4;
                    alu_in2 = pc_in;
                    aux_adder_in1 = pc_in;
                    aux_adder_in2 = imm;
                    pc_out = aux_adder_out;
                    flush_pipeline = 1;
                end
                OP_JALR: begin
                    alu_in1 = 4;
                    alu_in2 = pc_in;
                    pc_out = {aux_adder_out[M_WIDTH-1:1], 1'b0};
                    flush_pipeline = 1;
                end
                OP_INTEGER_IMM: begin
                    alu_in1 = rs1;
                    alu_in2 = imm;
                    alu_funct3 = funct3;
                    alu_modifier = imm[30];
                end
                OP_INTEGER: begin
                    alu_in1 = rs1;
                    alu_in2 = rs2;
                    alu_funct3 = funct3;
                    alu_modifier = funct7[5];
                end
                OP_BRANCH: begin
                    alu_in1 = rs1;
                    alu_in2 = rs2;
                    aux_adder_in1 = pc_in;
                    aux_adder_in2 = imm;
                    pc_out = aux_adder_out;
                    case (funct3)
                        F3_EQ: begin
                            alu_modifier = 1;
                            flush_pipeline = ~|alu_out;
                        end
                        F3_NE: begin
                            alu_modifier = 1;
                            flush_pipeline = |alu_out;
                        end
                        F3_LT: begin
                            alu_funct3 = F3_SLT;
                            flush_pipeline = |alu_out;
                        end
                        F3_GE: begin
                            alu_funct3 = F3_SLT;
                            flush_pipeline = ~|alu_out;
                        end
                        F3_LTU: begin
                            alu_funct3 = F3_SLTU;
                            flush_pipeline = |alu_out;
                        end
                        F3_GE: begin
                            alu_funct3 = F3_SLTU;
                            flush_pipeline = ~|alu_out;
                        end
                    endcase
                end
            endcase
        end
    end
end

reg [1:0] cycle;

always @ (posedge clk) begin
    if (en) begin
        if (op == OP_LOAD || op == OP_STORE) begin
            ready <= cycle == 2;

            if (cycle == 0)
                cycle <= 1;

            if (cycle == 1 && mem_ready)
                cycle <= 2;
        end

        else begin
            ready <= cycle;
            if (cycle == 0)
                cycle <= 1;
        end
    end else begin
        ready <= 0;
        cycle <= 0;
    end
end

endmodule
