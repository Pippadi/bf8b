`default_nettype none

module eightbit(
    input clk,
    input [7:0] data_in,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we
);

reg [7:0] a, b, pc, inst;

initial begin
    pc = 8'h00;
end

always @ (posedge clk) begin
    case (stage)
        4'h0: begin
            we = 0;
            addr = pc;
            stage <= stage + 1;
        end
        4'h1: begin
            inst = data_in;
            case (inst[7:6])
                2'b00: pc <= inst[5:0];
                2'b01: a <= a + b;
            endcase
            stage <= 0;
        end
        default:
            stage <= 0;
    endcase
end

endmodule
