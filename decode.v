module decode
#(
    parameter OP_LODI = 4'b0001
)
(
    input en,
    input clk,
    input [15:0] inst,
    output reg [3:0] op,
    output reg [3:0] reg0,
    output reg [3:0] reg1,
    output reg [3:0] reg2,
    output reg [7:0] addr,
    output reg [7:0] imm,
    output reg ready
);

always @ (posedge clk) begin
    if (en) begin
        op <= inst[15:12];
        reg0 <= inst[11:8];
        reg1 <= inst[7:4];
        reg2 <= inst[3:0];
        addr <= inst[7:0];
        if (op == OP_LODI)
            imm <= inst[7:0];
        else
            imm <= { {5{ inst[3] }},  inst[2:0] };
        ready <= 1;
    end
    else
        ready <= 0;
end

endmodule
