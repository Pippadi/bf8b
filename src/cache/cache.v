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
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg hit
);

reg [0:CELL_CNT-1] enables;

reg [ADDR_WIDTH+DATA_WIDTH-1:0] d_shiftin;
wire [(ADDR_WIDTH+DATA_WIDTH)*CELL_CNT-1:0] reg_data_packed;
reg [ADDR_WIDTH+DATA_WIDTH-1:0] reg_data [0:CELL_CNT-1];

integer i;
always @ (*) begin
    for (i = 0; i < CELL_CNT; i = i + 1) begin
        reg_data[i] = reg_data_packed[(ADDR_WIDTH+DATA_WIDTH)*i +: (ADDR_WIDTH+DATA_WIDTH)];
    end
end

// Shift register to hold data
// Address is in the upper bits, data is in the lower bits
// Position in the shift register indicates age
en_shift_reg #(
    .LENGTH(CELL_CNT),
    .WIDTH(ADDR_WIDTH+DATA_WIDTH)
) ShiftReg (
    .rst(rst),
    .clk(clk),
    .en(enables),
    .d(d_shiftin),
    .q_packed(reg_data_packed)
);

integer j;

reg [0:CELL_CNT-1] cmp_results;
wire [0:CELL_CNT-1] tempEnables;

prio_enabler #(
    .CELL_CNT(CELL_CNT)
) PrioEnabler (
    .cmp_results(cmp_results),
    .enables(tempEnables)
);

always @ (*) begin
    hit = 0;
    data_out = {DATA_WIDTH{1'b0}};
    cmp_results = 0;
    for (j = 0; j < CELL_CNT; j = j + 1) begin
        if (addr == reg_data[j][ADDR_WIDTH+DATA_WIDTH-1:DATA_WIDTH]) begin
            data_out = reg_data[j][DATA_WIDTH-1:0];
            hit = 1;
            cmp_results[j] = 1'b1;
        end
    end
end

// We don't want to spend a cycle shifting in and out the same data at the
// front of the shift register, so we keep track of the previous address
reg [ADDR_WIDTH-1:0] prevAddr;

always @ (posedge clk) begin
    prevAddr <= addr;

    // Shift in the requested data to make it the least aged
    if (we) begin
        d_shiftin <= {addr, data_in};
        enables <= tempEnables;
    end

    // Shift in the requested data to make it the least aged, overwriting
    // its old position in the cache
    else if (hit && addr != prevAddr) begin
        d_shiftin <= {addr, data_out};
        enables <= tempEnables;
    end

    else
        enables <= {CELL_CNT{1'b0}};
end

endmodule
