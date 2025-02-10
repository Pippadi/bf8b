module exec(
    input en,
    input clk,
    input [1:0] op,
    input [7:0] val1,
    input [7:0] val2,
    input [4:0] addr_in,
    input [7:0] mem_data_in,
    output reg [7:0] val_out,
    output reg [7:0] mem_addr,
    output reg [7:0] mem_data_out,
    output reg we,
    output reg ready
);

reg [1:0] stage;

always @ (posedge en) begin
    ready <= 0;
    if (op == 2'b01) begin
        we <= 0;
        mem_data_out <= 2'bxx;
    end else begin
        we <= 1;
        mem_data_out <= val1;
    end

    mem_addr <= {3'b111, addr_in};
    stage = 2'b00;
end

always @ (posedge clk) begin
    case (op)
        2'b01: begin
            case (stage)
                2'b00: stage <= 2'b01;
                2'b01: stage <= 2'b10;
                2'b10: begin
                    val_out <= mem_data_in;
                    ready <= 1;
                end
                default: ready <= ready;
            endcase
        end
        2'b10: begin
            if (stage > 0)
                ready <= 1;
            else
                stage <= 2'b01;
        end
    endcase
end

endmodule
