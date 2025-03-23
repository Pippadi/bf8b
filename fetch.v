module fetch(
    input en,
    input clk,
    input [7:0] data_in,
    input [7:0] pc,
    input mem_ready,
    output reg [7:0] addr,
    output reg [15:0] inst_out,
    output reg mem_req,
    output reg ready
);

reg [1:0] cycle;
reg hibyte;

always @ (posedge en) begin
    cycle <= 0;
    ready <= 0;
    mem_req <= 0;
end

always @ (negedge en) begin
    ready <= 0;
    mem_req <= 0;
    hibyte <= 1;
end

always @ (posedge clk) begin
    if (en) begin
        case (cycle)
            2'b00: begin
                addr <= (hibyte) ? pc : pc + 1;
                cycle <= 2'b01;
                mem_req <= 1;
            end
            2'b01: begin
                if (mem_ready) begin
                    mem_req <= 0;
                    if (hibyte) begin
                    inst_out[15:8] <= data_in;
                        cycle <= 2'b00;
                        hibyte <= 0;
                    end
                    else begin
                    inst_out[7:0] <= data_in;
                        cycle <= 2'b10;
                    end
                end
            end
            2'b10: begin
                ready <= 1;
            end
        endcase
    end
end

endmodule
