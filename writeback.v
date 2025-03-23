module writeback
#(
    parameter OP_LOD = 2'b01,
    parameter OP_ADD = 2'b11
)
(
    input en,
    input clk,
    input [1:0] op,
    input [3:0] reg_addr,
    input [7:0] val,
    output reg [7:0] regs [0:15],
    output reg ready
);

reg was_enabled;
reg [7:0] reg_file [0:15];

assign regs = reg_file;

always @ (posedge clk) begin
    was_enabled <= en;
    if (en & was_enabled) begin
        if (op == OP_LOD || op == OP_ADD) begin
            reg_file[reg_addr] = val;
        end
        ready <= 1;
    end
    else
        ready <= 0;
end

endmodule
