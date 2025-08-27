module mem_if
#(
    parameter M_WIDTH = 8,
    parameter CLIENT_CNT = 2,
    parameter MEM_ACC_8 = 2'b00,
    parameter MEM_ACC_16 = 2'b01,
    parameter MEM_ACC_32 = 2'b10
)
(
    input rst,
    input clk,
    input [CLIENT_CNT-1:0] client_requests,
    input [M_WIDTH-1:0] mem_data_in,
    input [CLIENT_CNT*M_WIDTH-1:0] client_addrs_packed,
    input [CLIENT_CNT-1:0] client_wes,
    input [2*CLIENT_CNT-1:0] client_data_widths_packed,
    input [CLIENT_CNT*M_WIDTH-1:0] client_data_outs_packed,
    output [M_WIDTH*CLIENT_CNT-1:0] client_data_ins_packed,
    output [CLIENT_CNT-1:0] client_readies,
    output reg [M_WIDTH-1:0] mem_data_out,
    output reg [M_WIDTH-$clog2(M_WIDTH/8)-1:0] mem_addr,
    output reg [M_WIDTH/8-1:0] mem_we_outs
);

reg [M_WIDTH-1:0] client_data_in;
reg client_ready;
wire client_we;
wire client_request;
wire [M_WIDTH-1:0] client_addr;
wire [1:0] client_data_width;
wire [M_WIDTH-1:0] client_data_out;

mem_mux #(
    .M_WIDTH(M_WIDTH),
    .CLIENT_CNT(CLIENT_CNT),
    .MEM_ACC_8(MEM_ACC_8),
    .MEM_ACC_16(MEM_ACC_16),
    .MEM_ACC_32(MEM_ACC_32)
) MemMux (
    .rst(rst),
    .clk(clk),
    .mem_data_in(mem_data_in),
    .client_requests(client_requests),
    .client_addrs_packed(client_addrs_packed),
    .client_wes(client_wes),
    .client_data_widths_packed(client_data_widths_packed),
    .client_data_outs_packed(client_data_outs_packed),
    .mem_ready(client_ready),
    .mem_request(client_request),
    .client_data_ins_packed(client_data_ins_packed),
    .client_readies(client_readies),
    .mem_data_out(client_data_out),
    .mem_addr(client_addr),
    .mem_data_width(client_data_width),
    .mem_we_out(client_we)
);

typedef enum bit[2:0] {
    MEM_IDLE = 3'b000,
    MEM_ACC_H_1 = 3'b001,
    MEM_ACC_H_2 = 3'b010,
    MEM_ACC_L_1 = 3'b011,
    MEM_ACC_L_2 = 3'b100,
    MEM_READY = 3'b101
} mem_state_t;

localparam BANK_SEL_WIDTH = $clog2(M_WIDTH/8);
localparam ADDR_WIDTH = M_WIDTH-BANK_SEL_WIDTH;

mem_state_t mem_cycle;
reg single_cycle_acc;

reg [BANK_SEL_WIDTH-1:0] shift_amt_temp;
reg [BANK_SEL_WIDTH-1:0] shift_amt_lo;
reg [BANK_SEL_WIDTH-1:0] shift_amt_hi;

always @ (*) begin
    mem_we_outs = 0;
    mem_addr = client_addr[M_WIDTH-1:BANK_SEL_WIDTH];
    shift_amt_temp = client_addr[BANK_SEL_WIDTH-1:0];

    case (mem_cycle)
        MEM_IDLE: if (client_request) begin
            single_cycle_acc = (client_data_width == MEM_ACC_8) 
                || (client_data_width == MEM_ACC_16 && shift_amt_lo != 3)
                || (client_data_width == MEM_ACC_32 && shift_amt_lo == 0);
            shift_amt_lo = shift_amt_temp;
            shift_amt_hi = ~shift_amt_lo + 1;
            client_data_in = 0;
            client_ready = 0;
        end

        MEM_ACC_H_1, MEM_ACC_H_2: begin
            mem_addr = client_addr[M_WIDTH-1:BANK_SEL_WIDTH] + 1;
            client_data_in = mem_data_in << (8*shift_amt_hi);
            mem_data_out = client_data_out >> (8*shift_amt_hi);
            client_ready = 0;

            case (client_data_width)
                MEM_ACC_16: mem_we_outs = {2{client_we}} >> shift_amt_hi;
                MEM_ACC_32: mem_we_outs = {4{client_we}} >> shift_amt_hi;
            endcase
        end

        MEM_ACC_L_1, MEM_ACC_L_2: begin
            client_data_in = client_data_in | (mem_data_in >> (8*shift_amt_lo));
            mem_data_out = client_data_out << (8*shift_amt_lo);

            case (client_data_width)
                MEM_ACC_8: mem_we_outs = client_we << shift_amt_lo;
                MEM_ACC_16: mem_we_outs = {2{client_we}} << shift_amt_lo;
                MEM_ACC_32: mem_we_outs = {4{client_we}} << shift_amt_lo;
            endcase

            client_ready = mem_cycle == MEM_ACC_L_2;
        end


        MEM_READY: client_ready = client_request;
    endcase
end

always @ (posedge clk) begin
    if (rst) begin
        mem_cycle <= MEM_IDLE;
    end else begin
        case (mem_cycle)
            MEM_IDLE: begin
                if (client_request)
                    mem_cycle <= single_cycle_acc ? MEM_ACC_L_1 : MEM_ACC_H_1;
            end

            MEM_ACC_H_1: mem_cycle <= MEM_ACC_H_2;
            MEM_ACC_H_2: mem_cycle <= MEM_ACC_L_1;
            MEM_ACC_L_1: mem_cycle <= MEM_ACC_L_2;
            MEM_ACC_L_2: mem_cycle <= MEM_READY;

            MEM_READY: mem_cycle <= client_request ? MEM_READY : MEM_IDLE;
        endcase
    end
end

endmodule
