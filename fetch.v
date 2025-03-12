module fetch(
    input en,
    input clk,
    input [7:0] data_in,
    input [7:0] pc,
    input mem_ready,
    output reg [7:0] addr,
    output reg [7:0] inst_out,
    output reg mem_req,
    output reg ready
);

reg [1:0] cycle;

always @ (posedge en) begin
    cycle <= 0;
    ready <= 0;
    mem_req <= 0;
end

always @ (negedge en) begin
    ready <= 0;
    mem_req <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        case (cycle)
            2'b00: begin
                addr <= pc;
                cycle <= 2'b01;
                mem_req <= 1;
            end
            2'b01: begin
                if (mem_ready) begin
                    inst_out <= data_in;
                    mem_req <= 0;
                    cycle <= 2'b10;
                end
            end
            2'b10: begin
                ready <= 1;
            end
        endcase
    end
end

endmodule
