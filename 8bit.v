`default_nettype none

module eightbit(
    input clk,
    input [7:0] data_in,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we
);

reg [7:0] a, b, pc, inst;
reg fetch_en;
wire fetch_ready, fetch_we;
wire [7:0] fetch_inst, fetch_addr, fetch_pc;

fetch pipe_fetch(.clk(clk), .en(fetch_en), .pc_in(pc), .data_in(data_in), .addr(fetch_addr), .pc(fetch_pc), .inst(fetch_inst), .we(fetch_we), .ready(fetch_ready));

initial begin
    pc = 8'h00;
    inst = 8'h00;
    fetch_en = 0;
end

always @ (posedge clk) begin
    if (~fetch_en) begin
        fetch_en <= 1;
    end

    if (fetch_ready) begin
        inst <= fetch_inst;
        fetch_en <= 0;
    end

    if (fetch_en) begin
        addr <= fetch_addr;
        we <= fetch_we;
        pc <= fetch_pc;
    end
end

endmodule

module fetch(
    input reg clk,
    input reg en,
    input reg [7:0] data_in,
    input reg [7:0] pc_in,
    output reg [7:0] addr,
    output reg [7:0] pc,
    output reg [7:0] inst,
    output reg we,
    output reg ready
);

reg [3:0] stage;

always @ (posedge en) begin
    stage <= 0;
    ready <= 0;
    addr <= pc_in;
    pc <= pc_in;
    we <= 0;
end

always @ (posedge clk) begin
    if (~ready)
        case (stage)
            4'h0: begin
                inst = data_in;
                addr = pc + 1;
                stage = 1;
            end
            4'h1: begin
                pc = pc + 2;
                ready = 1;
            end
        endcase
    end

    endmodule
