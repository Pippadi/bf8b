module exec
#(
    parameter OP_JMP = 4'b0000,
    parameter OP_LOD = 4'b0001,
    parameter OP_STR = 4'b0010,
    parameter OP_ADD = 4'b0011,
    parameter OP_ADDI = 4'b0100,
    parameter OP_LODI = 4'b0101,
    parameter OP_NAND = 4'b0110,
    parameter OP_JEQZ = 4'b0111
)
(
    input en,
    input clk,
    input [3:0] op,
    input [7:0] reg0,
    input [7:0] reg1,
    input [7:0] imm,
    input [7:0] mem_data_in,
    input mem_ready,
    output reg [7:0] pc_out,
    output reg [7:0] val_out,
    output reg [7:0] mem_addr,
    output reg [7:0] mem_data_out,
    output reg mem_req,
    output reg mem_we,
    output reg flush_pipeline,
    output reg ready
);

reg [1:0] cycle;

always @ (posedge clk) begin
    if (en) begin
        if (op == OP_LOD || op == OP_STR) begin
            ready <= cycle == 2;

            if (cycle == 0) begin
                mem_addr <= reg1 + imm;
                mem_we <= op == OP_STR;
                mem_data_out <= reg0;
                mem_req <= 1;
                cycle <= 1;
            end

            if (cycle == 1 && mem_ready) begin
                cycle <= 2;
                mem_req <= 0;
                val_out <= mem_data_in;
            end
        end else begin
            ready <= cycle;

            if (cycle == 0) begin
                if (op == OP_ADD || op == OP_ADDI)
                    val_out <= reg0 + (op == OP_ADDI ? imm : reg1);
                if (op == OP_LODI)
                    val_out <= imm;
                if (op == OP_NAND)
                    val_out <= ~(reg0 & reg1);
                if (op == OP_JMP || (op == OP_JEQZ && reg1 == 0)) begin
                    pc_out <= imm + reg0;
                    flush_pipeline <= 1;
                end
                cycle <= 1;
            end
        end
    end else begin
        ready <= 0;
        cycle <= 0;
        mem_req <= 0;
        flush_pipeline <= 0;
    end
end

endmodule
