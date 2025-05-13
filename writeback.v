module writeback
#(
    parameter M_WIDTH = 8,
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
    input [M_WIDTH-1:0] val,
    output reg [M_WIDTH*16-1:0] regs,
    output reg ready
);

reg [M_WIDTH-1:0] reg_file [0:15];

// Pack the unpacked register file
integer i;
always @ (*) begin
    for (i = 0; i < 16; i = i + 1) begin
        regs[M_WIDTH*i +: M_WIDTH] = reg_file[i];
    end
end

function automatic needs_writeback (input [3:0] op);
    needs_writeback =
        (op == OP_LOD) ||
        (op == OP_ADD) ||
        (op == OP_ADDI) ||
        (op == OP_LODI) ||
        (op == OP_NAND);
endfunction

always @ (posedge clk) begin
    if (en & needs_writeback(op))
        reg_file[reg_addr] <= val;
    ready <= en;
end

endmodule
