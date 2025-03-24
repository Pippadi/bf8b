module eightbit
#(
    parameter OP_JMP = 4'b0000,
    parameter OP_LOD = 4'b0001,
    parameter OP_STR = 4'b0010,
    parameter OP_ADD = 4'b0011,
    parameter OP_ADDI = 4'b0100,
    parameter OP_LODI = 4'b0101,
    parameter OP_NAND = 4'b0110,
    parameter OP_JEQZ = 4'b0111
)
(
    input rst,
    input clk,
    input mem_ready,
    inout [7:0] data,
    output reg [7:0] addr,
    output reg we,
    output reg mem_req
);

localparam STATE_IDLE = 2'b00;
localparam STATE_BUSY = 2'b10;
localparam STATE_COMPLETE = 2'b11;

wire [7:0] reg_file [15:0];

reg [7:0] a, b;
reg [7:0] pc;
reg [7:0] mem_data_out;

assign data = (we) ? mem_data_out : 8'hzz;

reg fetch_en;
reg fetch_mem_ready;
wire fetch_mem_req;
wire fetch_ready;
wire [7:0] fetch_addr;
wire [15:0] fetch_inst;
wire [1:0] fetch_state;

assign fetch_state = {fetch_en, fetch_ready};

fetch Fetch (
    .rst(rst),
    .en(fetch_en),
    .clk(clk),
    .data_in(data),
    .pc(pc),
    .mem_ready(fetch_mem_ready),
    .addr(fetch_addr),
    .inst_out(fetch_inst),
    .mem_req(fetch_mem_req),
    .ready(fetch_ready)
);

reg decode_en;
reg [15:0] decode_inst;
wire decode_ready;
wire [7:0] decode_addr;
wire [7:0] decode_imm;
wire [3:0] decode_op;
wire [3:0] decode_reg0, decode_reg1, decode_reg2;
wire [1:0] decode_state;

assign decode_state = {decode_en, decode_ready};

decode #(.OP_LODI(OP_LODI)) Decode (
    .en(decode_en),
    .clk(clk),
    .inst(decode_inst),
    .op(decode_op),
    .addr(decode_addr),
    .imm(decode_imm),
    .reg0(decode_reg0),
    .reg1(decode_reg1),
    .reg2(decode_reg2),
    .ready(decode_ready)
);

reg exec_en;
reg [3:0] exec_op;
reg [3:0] exec_reg_addr;
reg [7:0] exec_addr_in;
reg [7:0] exec_val1_in;
reg [7:0] exec_val2_in;
wire [7:0] exec_data_out;
wire exec_ready;

wire [7:0] exec_addr;
wire exec_we, exec_mem_req;
reg exec_mem_ready;
wire [7:0] exec_val_out;
wire [1:0] exec_state;

assign exec_state = {exec_en, exec_ready};

exec #(
    .OP_LOD(OP_LOD),
    .OP_STR(OP_STR),
    .OP_ADD(OP_ADD)
) Execute (
    .en(exec_en),
    .clk(clk),
    .op(exec_op),
    .val1(exec_val1_in),
    .val2(exec_val2_in),
    .addr_in(exec_addr_in),
    .mem_ready(exec_mem_ready),
    .mem_data_in(data),
    .val_out(exec_val_out),
    .mem_addr(exec_addr),
    .mem_data_out(exec_data_out),
    .mem_req(exec_mem_req),
    .we(exec_we),
    .ready(exec_ready)
);

reg wb_en;
reg [3:0] wb_op;
reg [3:0] wb_reg_addr;
wire wb_ready;
wire [1:0] wb_state;

assign wb_state = {wb_en, wb_ready};

writeback #(
    .OP_LOD(OP_LOD),
    .OP_ADD(OP_ADD)
) Writeback (
    .en(wb_en),
    .clk(clk),
    .op(exec_op),
    .reg_addr(wb_reg_addr),
    .val(exec_val_out),
    .regs(reg_file),
    .ready(wb_ready)
);

// For whether the fetch stage is holding the memory bus
reg mem_fetch_busy;

function automatic stage_should_rst(input[1:0] this_stage_state, next_stage_state);
    stage_should_rst = this_stage_state == STATE_COMPLETE && next_stage_state == STATE_IDLE;
endfunction

always @ (posedge rst) begin
    pc = 8'h00;
    fetch_en = 0;
    decode_en = 0;
    exec_en = 0;
    wb_en = 0;
    mem_fetch_busy = 0;
end

always @ (posedge clk) begin
    if (~rst) begin
        if (stage_should_rst(fetch_state, decode_state)) begin
            decode_inst <= fetch_inst;
            decode_en <= 1;
            fetch_en <= 0;
            pc <= pc + 2;
        end
        if (fetch_state == STATE_IDLE)
            fetch_en <= 1;

        if (stage_should_rst(decode_state, exec_state) && wb_state == STATE_IDLE) begin
            exec_op <= decode_op;
            exec_addr_in <= decode_addr;
            exec_reg_addr <= decode_reg0;
            decode_en <= 0;

            case (decode_op)
                OP_JMP: begin
                    pc <= decode_addr;
                    fetch_en <= 0;
                    decode_en <= 0;
                    exec_en <= 0;
                end
                OP_JEQZ: begin
                    if (reg_file[decode_reg0] == 0)
                        pc <= decode_addr;
                    fetch_en <= 0;
                    decode_en <= 0;
                    exec_en <= 0;
                end
                OP_LOD: exec_en <= 1;
                OP_STR: begin
                    exec_val1_in <= reg_file[decode_reg0];
                    exec_en <= 1;
                end
                OP_ADD: begin
                    exec_val1_in <= reg_file[decode_reg1];
                    exec_val2_in <= reg_file[decode_reg2];
                    exec_en <= 1;
                end
                OP_ADDI: begin
                    exec_val1_in <= reg_file[decode_reg1];
                    exec_val2_in <= decode_imm;
                    exec_en <= 1;
                end
                OP_LODI: begin
                    exec_val1_in <= decode_imm;
                    exec_en <= 1;
                end
                OP_NAND: begin
                    exec_val1_in <= reg_file[decode_reg1];
                    exec_val2_in <= reg_file[decode_reg2];
                    exec_en <= 1;
                end
            endcase
        end

        if (stage_should_rst(exec_state, wb_state)) begin
            exec_en <= 0;
            wb_op <= exec_op;
            wb_reg_addr <= exec_reg_addr;
            wb_en <= 1;
        end
        if (wb_state == STATE_COMPLETE) begin
            wb_en <= 0;
        end

        // Memory request muxing
        if (exec_mem_req & ~mem_fetch_busy) begin
            mem_req <= 1;
            addr <= exec_addr;
            mem_data_out <= exec_data_out;
            we <= exec_we;
            exec_mem_ready <= mem_ready;
        end else if (fetch_mem_req) begin
            mem_req <= 1;
            addr <= fetch_addr;
            mem_fetch_busy <= 1;
            we <= 0;
            fetch_mem_ready <= mem_ready;
        end else begin
            mem_req <= 0;
            mem_fetch_busy <= 0;
            we <= 0;
            fetch_mem_ready <= 0;
            exec_mem_ready <= 0;
        end
    end
end

endmodule
