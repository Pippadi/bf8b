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
    output [DATA_WIDTH-1:0] data_out,
    output hit
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

reg [CELL_CNT-1:0] cmp_results;
wire [$clog2(CELL_CNT)-1:0] hit_idx;
wire [0:CELL_CNT-1] temp_enables;

prio_enabler #(
    .CELL_CNT(CELL_CNT)
) PrioEnabler (
    .cmp_results(cmp_results),
    .hit_idx(hit_idx),
    .enables(temp_enables)
);

assign hit = |cmp_results;
assign data_out = hit ? reg_data[hit_idx][DATA_WIDTH-1:0] : {DATA_WIDTH{1'b0}};

integer j;
always @ (*) begin
    for (j = 0; j < CELL_CNT; j = j + 1)
        cmp_results[j] = addr == reg_data[j][ADDR_WIDTH+DATA_WIDTH-1:DATA_WIDTH];

    enables = {CELL_CNT{1'b0}};
    d_shiftin = {addr, data_in};
    if (we)
        enables = temp_enables;

    // Shift in the requested data to make it the least aged, overwriting
    // its old position in the cache. Only shift if the hit is not in the
    // first position.
    else if (hit && |temp_enables[1:CELL_CNT-1]) begin
        d_shiftin = {addr, data_out};
        enables = temp_enables;
    end
end

endmodule
