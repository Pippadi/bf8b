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

    initial begin
        a = 8'h00;
        b = 8'h00;
        pc = 8'h00;
        inst = 8'h00;
        pipe = 3'h0;
        inst_stage = 4'h00;
        we = 1'b0;
        alu_do = 0;
        addr = pc;
    end

    alu ALU(.r1(a), .r2(b), .inst(inst), .en(alu_do));

    endmodule

    module alu(
        input reg [7:0] r1,
        input reg [7:0] r2,
        input reg [7:0] inst,
        input en
        );
        always @ (posedge en) begin
            case (instr[7:0])
                8'h10: a = a + b;
                8'h11: a = a - b;
                8'h12: a = a * b;
                8'h13: a = a / b;
                8'h14: a = a & b;
                8'h15: a = a | b;
                8'h16: a = a ^ b;
                8'h17: a = ~a;
                default: ;
            endcase
        end
        endmodule
