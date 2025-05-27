module exec
#(
    parameter M_WIDTH = 8,
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
    output reg mem_req,
    output reg mem_we,
    output reg flush_pipeline,
    output reg ready
);

reg [1:0] cycle;

always @ (posedge clk) begin
    if (en) begin
        case (cycle)
            0: begin
                case (op)
                    OP_LUI: val_out <= imm;
                    OP_AIUPC: val_out <= pc_in + imm;
                    OP_JAL: begin
                        pc_out <= pc_in + imm;
                        val_out <= pc_in + 4;
                        flush_pipeline <= 1;
                    end
                    OP_JALR: begin
                        pc_out <= {(imm + rs1)[M_WIDTH-1:1], 1'b0};
                        val_out <= pc_in + 4;
                        flush_pipeline <= 1;
                    end
                endcase
                cycle <= 2;
            end

            2: ready <= 1;
        endcase
    end else begin
        ready <= 0;
        cycle <= 0;
        mem_req <= 0;
        flush_pipeline <= 0;
    end
end

endmodule
