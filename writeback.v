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
    input [7:0] val,
    output reg [7:0] a,
    output reg [7:0] b,
    output reg ready
);

always @ (posedge en or negedge en) begin
    ready <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        if (op == OP_LOD || op == OP_ADD) begin
            if (srcdst) begin
                b <= val;
            end
            else begin
                a <= val;
            end
            ready <= 1;
        end
        else begin
            a <= a;
            b <= b;
            ready <= 1;
        end
    end
end

endmodule
