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

integer j;
integer eldest;
always @ (posedge clk) begin
    if (~rst) begin
        if (we) begin
            hit = 0;
            eldest = 0;
            for (j = 0; j < CELL_CNT; j = j + 1) begin
                if (initialized != {CELL_CNT{1'b1}}) begin
                    if (!initialized[j]) begin
                        eldest = j;
                    end
                end
                else begin
                    if (ages[j] > ages[eldest]) begin
                        eldest = j;
                    end
                end
        end

        addrs[eldest] = addr;
        datas[eldest] = data;
        ages[eldest] = 0;
        initialized[eldest] = 1;

        for (j = 0; j < CELL_CNT; j = j + 1) begin
            if (j != eldest && initialized[j])
                ages[j] = ages[j] + 1;
        end
    end

    else begin
        hit = 0;
        for (j = 0; j < CELL_CNT; j = j + 1) begin
            if (addrs[j] == addr && initialized[j]) begin
                data_reg = datas[j];
                hit = 1;
            end
        end
    end
end
    end

    always @ (posedge rst) begin
        hit = 0;
        for (j = 0; j < CELL_CNT; j = j + 1) begin
            initialized = 0;
            addrs[j] = 0;
            datas[j] = 0;
            ages[j] = 0;
            data_reg = 0;
        end
    end

    endmodule
