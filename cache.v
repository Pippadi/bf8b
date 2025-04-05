// A multi-bit-wide shift register with exposed enables for each word
module shift_reg
#(
    parameter LENGTH = 8,
    parameter WIDTH = 8
)
(
    input rst,
    input clk,
    input [0:LENGTH-1] en,
    input [WIDTH-1:0] d,
    output reg [LENGTH * WIDTH - 1:0] q_packed
);

reg [WIDTH-1:0] ds [LENGTH-1:0];
reg [WIDTH-1:0] q [0:LENGTH-1];

integer i;
always @ (*) begin
    // Pack the register file to satisfy more strict Verilog rules
    for (i = 0; i < LENGTH; i = i + 1)
        q_packed[WIDTH*i +: WIDTH] = q[i];

    // Prepare the flip flops' D inputs
    ds[0] = d;
    for (i = 1; i < LENGTH; i = i + 1)
        ds[i] = q[i-1];
end

integer j;
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
assign data = (we) ? 'hz : data_reg;

reg [0:CELL_CNT-1] enables;

reg [ADDR_WIDTH+DATA_WIDTH-1:0] d_shiftin;
wire [(ADDR_WIDTH+DATA_WIDTH)*CELL_CNT-1:0] reg_data_packed;
reg [ADDR_WIDTH+DATA_WIDTH-1:0] reg_data [0:CELL_CNT-1];

integer i;
always @ (*) begin
    for (i = 0; i < 16; i = i + 1) begin
        reg_data[i] = reg_data_packed[(ADDR_WIDTH+DATA_WIDTH)*i +: (ADDR_WIDTH+DATA_WIDTH)];
    end
end

// Shift register to hold data
// Address is in the upper bits, data is in the lower bits
// Position in the shift register indicates age
shift_reg #(
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

// Temporary variables for combinational logic in order to do nonblocking
// assigns to real registers
reg [0:CELL_CNT-1] tempEnables;
reg tempHit;
reg [DATA_WIDTH-1:0] tempDataOut;

// We don't want to spend a cycle shifting in and out the same data at the
// front of the shift register, so we keep track of the previous address
reg [ADDR_WIDTH-1:0] prevAddr;

// Give the shift register a cycle to shift in data
reg shiftCycle;

always @ (posedge clk) begin
    prevAddr <= addr;
    if (~shiftCycle) begin
        tempEnables = {CELL_CNT{1'b1}};
        tempHit = 0;
        for (j = 0; j < CELL_CNT; j = j + 1) begin
            if (addr == reg_data[j][ADDR_WIDTH+DATA_WIDTH-1:DATA_WIDTH]) begin
                tempDataOut = reg_data[j][DATA_WIDTH-1:0];
                tempHit = 1;
                // Age all the data above this one
                tempEnables = tempEnables << (CELL_CNT-j-1);
            end
        end
        hit <= tempHit;
        data_reg <= tempDataOut;

        // Shift in the requested data to make it the least aged
        if (we) begin
            d_shiftin <= {addr, data};
            enables <= tempEnables;
            shiftCycle <= 1;
        end

        // Shift in the requested data to make it the least aged, overwriting
        // its old position in the cache
        else if (tempHit && addr != prevAddr) begin
            d_shiftin <= {addr, tempDataOut};
            enables <= tempEnables;
            shiftCycle <= 1;
        end

        else
            enables <= {CELL_CNT{1'b0}};
    end
    else begin
        enables <= {CELL_CNT{1'b0}};
        shiftCycle = 0;
    end
end

endmodule
