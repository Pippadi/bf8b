module cache
#(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter CELL_CNT = 4
)
(
    input rst,
    input clk,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    inout [DATA_WIDTH-1:0] data,
    output reg hit
);

reg [DATA_WIDTH-1:0] data_reg;

reg [ADDR_WIDTH-1:0] addrs [0:CELL_CNT-1];
reg [DATA_WIDTH-1:0] datas [0:CELL_CNT-1];
reg [$clog2(CELL_CNT)-1:0] ages [0:CELL_CNT-1];
reg [CELL_CNT-1:0] initialized;

assign data = (we) ? 'hz : data_reg;

integer i;
integer hitIdx;
integer eldest;

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        hit = 0;
        initialized = 0;
        data_reg = 0;
        for (i = 0; i < CELL_CNT; i = i + 1) begin
            addrs[i] = 0;
            datas[i] = 0;
            ages[i] = 0;
        end
    end
    else begin
        hit = 0;
        for (i = 0; i < CELL_CNT; i = i + 1) begin
            if (addrs[i] == addr && initialized[i]) begin
                data_reg = datas[i];
                hit = 1;
                hitIdx = i;
            end
        end

        if (we) begin
            if (hit) begin
                datas[hitIdx] = data;
                ages[hitIdx] = 0;
            end
            else begin
                eldest = 0;
                for (i = 0; i < CELL_CNT; i = i + 1) begin
                    if (initialized != {CELL_CNT{1'b1}}) begin
                        if (!initialized[i])
                            eldest = i;
                    end
                    else begin
                        if (ages[i] > ages[eldest])
                            eldest = i;
                    end
                end

                addrs[eldest] = addr;
                datas[eldest] = data;
                ages[eldest] = 0;
                initialized[eldest] = 1;

                for (i = 0; i < CELL_CNT; i = i + 1) begin
                    if (i != eldest && initialized[i])
                        ages[i] = ages[i] + 1;
                end
            end
        end
    end
end

endmodule
