module exec
#(
    parameter OP_LOD = 4'b0001,
    parameter OP_STR = 4'b0010,
    parameter OP_ADD = 4'b0011
)
(
    input en,
    input clk,
    input [1:0] op,
    input [7:0] val1,
    input [7:0] val2,
    input [7:0] addr_in,
    input [7:0] mem_data_in,
    input mem_ready,
    output reg [7:0] val_out,
    output reg [7:0] mem_addr,
    output reg [7:0] mem_data_out,
    output reg mem_req,
    output reg we,
    output reg ready
);

reg cycle;

always @ (posedge en) begin
    ready <= 0;

    if (op == 2'b10) begin
        we <= 1;
        mem_data_out <= val1;
    end else begin
        mem_data_out <= 8'hxx;
        we <= 0;
    end

    mem_addr <= addr_in;
    cycle <= 0;
end

always @ (negedge en) begin
    ready <= 0;
end

always @ (posedge clk) begin
    if (en) begin
        if (op == OP_LOD || op == OP_STR) begin
            if (~cycle) begin
                cycle <= 2'b01;
                mem_req <= 1;
            end else if (mem_ready) begin
                mem_req <= 0;
                ready <= 1;
                if (op == 2'b01)
                    val_out <= mem_data_in;
            end
        end
        else begin
            val_out <= val1 + val2;
            ready <= 1;
        end
    end
end

endmodule
