module fetch
#(
    parameter M_WIDTH = 32,
    parameter OP_WIDTH = 7,
    parameter REG_ADDR_WIDTH = 5,
    parameter INST_WIDTH = 32,
    parameter OP_LUI = 7'b0110111,
    parameter OP_AUIPC = 7'b0010111,
    parameter OP_JAL = 7'b1101111,
    parameter OP_JALR = 7'b1100111,
    parameter OP_LOAD = 7'b0000011,
    parameter OP_STORE = 7'b0100011,
    parameter OP_BRANCH = 7'b1100011,
    parameter OP_INTEGER_IMM = 7'b0010011,
    parameter OP_INTEGER = 7'b0110011
)
(
    input rst,
    input en,
    input clk,
    input [M_WIDTH-1:0] data_in,
    input [M_WIDTH-1:0] pc,
    input mem_ready,
    output reg [M_WIDTH-1:0] addr,
    output reg mem_req,
    output reg ready,

    output wire [OP_WIDTH-1:0] op,
    output wire [REG_ADDR_WIDTH-1:0] rd_addr,
    output wire [M_WIDTH-1:0] imm,
    output wire [2:0] funct3,
    output wire [6:0] funct7,
    output wire [REG_ADDR_WIDTH-1:0] rs1_addr,
    output wire [REG_ADDR_WIDTH-1:0] rs2_addr
);

localparam QUERY_CACHE = 2'b00;
localparam MEM_WAIT = 2'b01;
localparam UPDATE_CACHE = 2'b10;
localparam DONE = 2'b11;

reg cache_req, cache_we;
wire cache_hit, cache_ready;
wire [INST_WIDTH-1:0] cache_inst;
reg [INST_WIDTH-1:0] inst;

cache #(
    .DATA_WIDTH(INST_WIDTH),
    .ADDR_WIDTH(M_WIDTH),
    .CELL_CNT(32)
) ICache (
    .rst(rst),
    .clk(clk),
    .req(cache_req),
    .we(cache_we),
    .addr(pc),
    .data_in(inst),
    .data_out(cache_inst),
    .ready(cache_ready),
    .hit(cache_hit)
);

instruction_decode #(
    .M_WIDTH(M_WIDTH),
    .OP_WIDTH(OP_WIDTH),
    .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
    .INST_WIDTH(INST_WIDTH),
    .OP_LUI(OP_LUI),
    .OP_AUIPC(OP_AUIPC),
    .OP_JAL(OP_JAL),
    .OP_JALR(OP_JALR),
    .OP_LOAD(OP_LOAD),
    .OP_STORE(OP_STORE),
    .OP_BRANCH(OP_BRANCH),
    .OP_INTEGER_IMM(OP_INTEGER_IMM),
    .OP_INTEGER(OP_INTEGER)
) InstructionDecode (
    .inst(inst),
    .op(op),
    .rd_addr(rd_addr),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .imm(imm),
    .funct7(funct7),
    .funct3(funct3)
);

reg [1:0] cycle;

always @ (*) begin
    mem_req = 0;
    cache_req = 0;
    cache_we = 0;
    addr = pc;

    ready = cycle == DONE;

    if (~rst & en) begin
        case (cycle)
            QUERY_CACHE: cache_req = ~cache_ready;
            MEM_WAIT: mem_req = 1;
            UPDATE_CACHE: begin
                cache_we = 1;
                cache_req = ~cache_ready;
            end
            DONE: cache_we = 0;
        endcase
    end
end

always @ (posedge clk) begin
    if (~rst & en) begin
        case (cycle)
            QUERY_CACHE: begin
                cycle <= cache_ready ? (cache_hit ? DONE : MEM_WAIT) : QUERY_CACHE;
                inst <= cache_inst;
            end
            MEM_WAIT: begin
                cycle <= mem_ready ? UPDATE_CACHE : MEM_WAIT;
                inst <= data_in;
            end
            UPDATE_CACHE: cycle <= cache_ready ? UPDATE_CACHE : DONE;
        endcase
    end else begin
        cycle <= QUERY_CACHE;
        inst <= 0;
    end
end

endmodule
