module mem_if
#(
    parameter CLIENT_CNT = 2
)
(
    input rst,
    input clk,
    input [CLIENT_CNT-1:0] requests,
    input [CLIENT_CNT * 8 - 1:0] addrs,
    input [CLIENT_CNT-1:0] wes,
    input [CLIENT_CNT*8-1:0] data_outs,
    output reg [CLIENT_CNT-1:0] readies,
    output reg [7:0] data_out,
    output reg [7:0] addr,
    output reg we
);

// For whether the exec stage is holding the memory bus
reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder;
reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder_temp;
reg [1:0] mem_cycle;
integer i;

always @ (posedge clk) begin
    if (rst) begin
        mem_mux_holder <= 0;
        mem_cycle <= 0;
        readies <= 0;
    end else begin
        case (mem_cycle)
            0: begin
                if (requests) begin
                    for (i = 0; i < CLIENT_CNT; i = i + 1) begin
                        if (requests[i])
                            mem_mux_holder_temp = i;
                    end
                    mem_mux_holder <= mem_mux_holder_temp;
                    addr <= addrs[mem_mux_holder_temp*8 +: 8];
                    we <= wes[mem_mux_holder_temp];
                    data_out <= data_outs[mem_mux_holder_temp*8 +: 8];
                    mem_cycle <= 1;
                end else begin
                    mem_mux_holder <= 0;
                    we <= 0;
                end
            end
            1: begin
                readies[mem_mux_holder] <= 1;
                we <= 0;
                mem_cycle <= 2;
            end
            2: begin
                if (~requests[mem_mux_holder]) begin
                    readies <= 0;
                    mem_cycle <= 0;
                end
            end
        endcase
    end
end

endmodule
