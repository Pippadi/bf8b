module writeback
#(
    parameter OP_LOD = 4'b0001,
    parameter OP_ADD = 4'b0011,
    parameter OP_ADDI = 4'b0100,
    parameter OP_LODI = 4'b0101,
    parameter OP_NAND = 4'b0110
)
(
    input en,
    input clk,
    input [3:0] op,
    input [3:0] reg_addr,
    input [7:0] val,
    output reg [7:0] regs [0:15],
    output reg ready
);

reg was_enabled;
reg [7:0] reg_file [0:15];

assign regs = reg_file;

function automatic needs_writeback (input [1:0] op);
    needs_writeback =
        (op == OP_LOD) ||
        (op == OP_ADD) ||
        (op == OP_ADDI) ||
        (op == OP_LODI) ||
        (op == OP_NAND);
endfunction

always @ (posedge clk) begin
    was_enabled <= en;
    if (en & was_enabled) begin
        if (needs_writeback(op)) begin
            reg_file[reg_addr] = val;
        end
        ready <= 1;
    end
    else
        ready <= 0;
end

endmodule
