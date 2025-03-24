module cache
#(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter CELL_CNT = 4,
)
(
    input rst,
    input req,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    inout [DATA_WIDTH-1:0] data,
    output reg hit
);

reg [DATA_WIDTH-1:0] data_reg;

reg [ADDR_WIDTH-1:0] addrs [0:CELL_CNT-1];
reg [DATA_WIDTH-1:0] datas [0:CELL_CNT-1];
reg [$clog2(CELL_CNT)-1:0] ages [0:CELL_CNT-1];

assign data = (we) ? 'hz : data_reg;

integer j;
integer eldest;
always @ (*) begin
    if (~rst) begin
        if (req) begin
            hit = 0;
            for (j = 0; j < CELL_CNT; j = j + 1) begin
                if (addrs[j] == addr) begin
                    data_reg = datas[j];
                    hit = 1;
                end
            end
        end

        else if (we) begin
            eldest = 0;
            for (j = 0; j < CELL_CNT; j = j + 1) begin
                if (ages[j] > ages[eldest])
                    eldest = j;
            end

            addrs[eldest] = addr;
            datas[eldest] = data;
            ages[eldest] = 0;

            for (j = 0; j < CELL_CNT; j = j + 1) begin
                if (j != eldest)
                    ages[j] = ages[j] + 1;
            end
        end
    end
end

endmodule
