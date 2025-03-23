module decode(
    input en,
    input clk,
    input [15:0] inst,
    output reg [1:0] op,
    output reg srcdst,
    output reg [7:0] addr,
    output reg ready
);

reg was_enabled;

always @ (posedge clk) begin
    was_enabled <= en;
    if (en & was_enabled) begin
        op <= inst[15:14];
        case (inst[15:14])
            2'b00: addr <= inst[13:8];
            2'b11: begin
                addr <= 0;
                srcdst <= inst[13];
            end
            default: begin
                addr <= inst[7:0];
                srcdst <= inst[13];
            end
        endcase
        ready <= 1;
    end
    else
        ready <= 0;
end

endmodule
