module decode(
    input en,
    input clk,
    input [15:0] inst,
    output reg [3:0] op,
    output reg [3:0] reg0,
    output reg [3:0] reg1,
    output reg [3:0] reg2,
    output reg [7:0] addr,
    output reg ready
);

reg was_enabled;

always @ (posedge clk) begin
    was_enabled <= en;
    if (en & was_enabled) begin
        op <= inst[15:12];
        reg0 <= inst[11:8];
        case (inst[15:12])
            4'b0011: begin
                addr <= 0;
                reg1 <= inst[7:4];
                reg2 <= inst[3:0];
            end
            default: begin
                addr <= inst[7:0];
            end
        endcase
        ready <= 1;
    end
    else
        ready <= 0;
end

endmodule
