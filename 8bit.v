`default_nettype none

module eightbit(
    input reg clk,
    input reg [7:0] data_in,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we
);

reg [7:0] a, b, pc, inst;
reg [3:0] inst_stage;
reg alu_do;

alu ALU(.r1(a), .r2(b), .inst(inst), .en(alu_do));

initial begin
    pc = 8'h00;
    inst = 8'h00;
    inst_stage = 4'h0;
    we = 1'b0;
    alu_do = 0;
    addr = pc;
end

endmodule

module alu(
    input en,
    input reg [7:0] inst,
    input reg [7:0] r2,
    output reg [7:0] r1
);

always @ (posedge en) begin
    case (inst)
        8'h10: r1 = r1 + r2;
        8'h11: r1 = r1 - r2;
        8'h12: r1 = r1 * r2;
        8'h13: r1 = r1 / r2;
        8'h14: r1 = r1 & r2;
        8'h15: r1 = r1 | r2;
        8'h16: r1 = r1 ^ r2;
        8'h17: r1 = ~r1;
        default: ;
    endcase
end

endmodule
