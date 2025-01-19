module fetch(
    input fetch_en,
    input clk,
    input [7:0] data_in,
    input [7:0] pc,
    output reg [7:0] addr,
    output reg [7:0] inst_out,
    output reg ready
);

reg [1:0] stage;

always @ (posedge fetch_en) begin
    stage <= 0;
    ready <= 0;
end

always @ (posedge clk) begin
    if (fetch_en) begin
        case (stage)
            2'b00: begin
                addr <= pc;
                stage <= 1;
            end
            2'b01: stage <= 2;
            2'b10: begin
                $display("fetch: %h", data_in);
                inst_out <= data_in;
                ready <= 1;
                stage <= 3;
            end
            default: ready <= ready;
        endcase
    end
end

endmodule
