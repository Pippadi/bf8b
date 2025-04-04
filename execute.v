module exec
#(
    parameter OP_LOD = 4'b0001,
    parameter OP_STR = 4'b0010,
    parameter OP_ADD = 4'b0011,
    parameter OP_ADDI = 4'b0100,
    parameter OP_LODI = 4'b0101,
    parameter OP_NAND = 4'b0110
)
(
    input en,
    input clk,
    input [3:0] op,
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

always @ (posedge clk or posedge en) begin
    if (en) begin
        if (op == OP_LOD || op == OP_STR) begin
            if (~cycle) begin
                mem_addr <= addr_in;
                we <= op == OP_STR;
                mem_data_out <= val1;
                cycle <= 2'b01;
                mem_req <= 1;
            end else if (mem_ready) begin
                mem_req <= 0;
                ready <= 1;
                if (op == OP_LOD)
                    val_out <= mem_data_in;
            end
        end
        else begin
            case(op)
                OP_ADD:
                    val_out <= val1 + val2;
                OP_ADDI:
                    val_out <= val1 + val2;
                OP_LODI:
                    val_out <= val1;
                OP_NAND:
                    val_out <= ~(val1 & val2);
            endcase
            ready <= 1;
        end
    end

    else begin
        ready <= 0;
        cycle <= 0;
        we <= 0;
    end
end

endmodule
