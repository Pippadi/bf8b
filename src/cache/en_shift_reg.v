// A multi-bit-wide shift register with exposed enables for each word
module en_shift_reg
#(
    parameter LENGTH = 8,
    parameter WIDTH = 8
)
(
    input rst,
    input clk,
    input [LENGTH-1:0] en,
    input [WIDTH-1:0] d,
    output reg [LENGTH * WIDTH - 1:0] q_packed
);

reg [WIDTH-1:0] ds [LENGTH-1:0];
reg [WIDTH-1:0] q [0:LENGTH-1];

integer i;
always @ (*) begin
    // Pack the register file to satisfy more strict Verilog rules
    for (i = 0; i < LENGTH; i = i + 1)
        q_packed[WIDTH*i +: WIDTH] = q[i];

    // Prepare the flip flops' D inputs
    ds[0] = d;
    for (i = 1; i < LENGTH; i = i + 1)
        ds[i] = q[i-1];
end

integer j;
always @ (posedge clk) begin
    if (rst) begin
        for (j = 0; j < LENGTH; j = j + 1)
            q[j] <= {WIDTH{1'b1}};
    end
    else begin
        for (j = 0; j < LENGTH; j = j + 1) begin
            if (en[j])
                q[j] <= ds[j];
        end
    end
end

endmodule
