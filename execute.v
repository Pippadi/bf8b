module exec(
    input en,
    input clk,
    input [1:0] op,
    input [7:0] val1,
    input [7:0] val2,
    input [4:0] addr_in,
    input [7:0] mem_data_in,
    input mem_ready,
    output reg [7:0] val_out,
    output reg [7:0] mem_addr,
    output reg [7:0] mem_data_out,
    output reg mem_req,
    output reg we,
    output reg ready
);

reg [1:0] cycle;

always @ (posedge en) begin
    ready <= 0;

    if (op == 2'b10) begin
        we <= 1;
        mem_data_out <= val1;
    end else begin
        mem_data_out <= 8'hxx;
        we <= 0;
    end

    mem_addr <= {3'b111, addr_in};
    cycle = 2'b00;
end

always @ (negedge en) begin
    ready <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        if (op == 2'b10 || op == 2'b01) begin
            case (cycle)
                2'b00: begin
                    cycle <= 2'b01;
                    mem_req <= 1;
                end
                2'b01: if (mem_ready) begin
                    cycle <= 2'b10;
                    mem_req <= 0;
                    if (op == 2'b01)
                        val_out <= mem_data_in;
                end
                2'b10: ready <= 1;
            endcase
        end
        else begin
            val_out <= val1 + val2;
            ready <= 1;
        end
    end
end

endmodule
