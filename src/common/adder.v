module adder
#(
    parameter M_WIDTH = 32
)
(
    input cin,
    input [M_WIDTH-1:0] in1,
    input [M_WIDTH-1:0] in2,
    output [M_WIDTH-1:0] out
);

assign out = in1 + in2 + cin;

endmodule
