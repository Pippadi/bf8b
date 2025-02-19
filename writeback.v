module writeback(
    input en,
    input clk,
    input [1:0] op,
    input srcdst,
    input [7:0] val,
    output reg [7:0] a,
    output reg [7:0] b,
    output reg ready
);

always @ (posedge en) begin
    ready <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        if (op == 2'b01 || op == 2'b11) begin
            if (srcdst) begin
                a <= val;
            end
            else begin
                b <= val;
            end
            ready <= 1;
        end
        else begin
            a <= a;
            b <= b;
        end
    end
end

endmodule
