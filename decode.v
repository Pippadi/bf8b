module decode(
    input en,
    input clk,
    input [7:0] inst,
    output reg [1:0] inst_type,
    output reg srcdst,
    output reg [5:0] addr,
    output reg ready
);

always @ (posedge en or negedge en) begin
    ready <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        inst_type = inst[7:6];
        case (inst_type)
            2'b00: addr = inst[5:0];
            2'b01: begin
                addr = {1'b0, inst[4:0]};
                srcdst = inst[5];
            end
            2'b10: begin
                addr = {1'b0, inst[4:0]};
                srcdst = inst[5];
            end
            2'b11: begin
                addr = 0;
                srcdst = inst[5];
            end
        endcase
        ready = 1;
    end
end

endmodule
