module decode_exec(
    input en,
    input clk,
    input [7:0] inst,
    input [7:0] data_in,
    output reg [7:0] pc,
    output reg [7:0] a,
    output reg [7:0] b,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we,
    output reg ready
);

reg jump_en, jump_ready;

jump Jump (
    .en(jump_en),
    .clk(clk),
    .inst(inst),
    .pc(pc)
);

always @ (posedge en) begin
    ready <= 1'b0;
end

always @ (posedge clk) begin
    if (en) begin
        a = a;
        b = b;
        we = 0;
        addr = addr;
        data_out = data_out;

        if (~ready) begin
            case (inst[7:6])
                2'b00: begin
                    jump_en = 1;
                end
            endcase
        end else begin
            jump_en = 0;
        end
    end
end

endmodule

module jump (
    input en,
    input clk,
    input [7:0] inst,
    output reg [7:0] pc
);

always @ (posedge en)
    pc <= {2'b00, inst[5:0]};

always @ (posedge clk) begin
    if (~en) begin
        pc <= pc;
    end
end

endmodule
