module shift_reg
(
    parameter LENGTH = 8,
    parameter WIDTH = 8
)
(
    input rst,
    input clk,
    input [LENGTH-1:0] en,
    input [WIDTH-1:0] d,
    output reg [LENGTH * WIDTH - 1:0] q_packed
);

reg [WIDTH-1:0] q [0:LENGTH-1];

integer i;
always @ (*) begin
    for (i = 0; i < LENGTH; i = i + 1) begin
        q_packed[WIDTH*i +: WIDTH] = q[i];
    end
end

integer j;
wire [WIDTH-1:0] d [LENGTH-1:0];
assign ds = {d, q[LENGTH-1:1]};

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        for (j = 0; j < LENGTH; j = j + 1) begin
            q[j] <= {WIDTH{1'b1}};
        end
    end
    else begin
        for (j = 0; j < LENGTH; j = j + 1) begin
            if (en[j])
                q[j] <= ds[j];
        end
    end
end

endmodule

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
reg [CELL_CNT-1:0] enables;

wire [(ADDR_WIDTH+DATA_WIDTH)*CELL_CNT-1:0] reg_data_packed;
wire [ADDR_WIDTH+DATA_WIDTH-1:0] reg_data [0:CELL_CNT-1];

integer i;
always @ (*) begin
    for (i = 0; i < 16; i = i + 1) begin
        reg_file[i] = reg_data_packed[8*i +: 8];
    end
end

shift_reg #(
    .LENGTH(CELL_CNT),
    .WIDTH(ADDR_WIDTH+DATA_WIDTH)
) ShiftReg (
    .rst(rst),
    .clk(clk),
    .en(enables),
    .d(),
    .qs(reg_data_packed)
);

assign data = (we) ? 'hz : data_reg;

integer j;
integer hitIdx;
always @ (posedge clk) begin
    for (j = 0; j < CELL_CNT; j = j + 1) begin
        if (addr == reg_data[j][ADDR_WIDTH+DATA_WIDTH:DATA_WIDTH]) begin
            data_reg <= reg_data[j][DATA_WIDTH-1:0];
            hitIdx = j;
        end
    end
end

endmodule
