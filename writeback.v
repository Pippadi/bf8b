module writeback
#(
    parameter OP_LOD = 2'b01,
    parameter OP_ADD = 2'b11
)
(
    input en,
    input clk,
    input [1:0] op,
    input srcdst,
    input [7:0] a_in,
    input [7:0] b_in,
    input [7:0] val,
    output reg [7:0] a_out,
    output reg [7:0] b_out,
    output reg ready
);

always @ (posedge en or negedge en) begin
    ready <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        if (op == OP_LOD || op == OP_ADD) begin
            if (srcdst) begin
                b_out <= val;
            a_out <= a_in;
        end
            else begin
                a_out <= val;
            b_out <= b_in;
        end
        end
        else begin
            a_out <= a_in;
            b_out <= b_in;
        end
        ready <= 1;
    end
end

endmodule
