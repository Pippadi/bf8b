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
    output reg [M_WIDTH*CLIENT_CNT-1:0] client_data_ins_packed,
    output reg [CLIENT_CNT-1:0] client_readies,
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

localparam BANK_SEL_WIDTH = $clog2(M_WIDTH/8);
localparam ADDR_WIDTH = M_WIDTH-BANK_SEL_WIDTH;

reg [1:0] mem_cycle;
reg [1:0] prev_mem_cycle;

reg [BANK_SEL_WIDTH-1:0] shift_amt_temp;
reg [BANK_SEL_WIDTH-1:0] shift_amt_0;
reg [BANK_SEL_WIDTH-1:0] shift_amt_1;

always @ (*) begin
    mem_we_outs = 0;
    shift_amt_temp = client_addr[BANK_SEL_WIDTH-1:0];
    case (mem_cycle)
        0: if (client_request) begin
            shift_amt_0 = shift_amt_temp;
            shift_amt_1 = ~shift_amt_0 + 1;
            mem_addr = client_addr[M_WIDTH-1:BANK_SEL_WIDTH];
            mem_data_out = client_data_out << (8*shift_amt_0);
            client_ready = 0;

            case (client_data_width)
                MEM_ACC_8: mem_we_outs = client_we << shift_amt_0;
                MEM_ACC_16: mem_we_outs = {2{client_we}} << shift_amt_0;
                MEM_ACC_32: mem_we_outs = {4{client_we}} << shift_amt_0;
            endcase
        end

        1: begin
            mem_addr = client_addr[M_WIDTH-1:BANK_SEL_WIDTH] + 1;
            mem_data_out = client_data_out << (8*shift_amt_1);
            client_data_in = mem_data_in >> (8*shift_amt_0);
            client_ready = 0;
            case (client_data_width)
                MEM_ACC_16: mem_we_outs = {2{client_we}} >> shift_amt_1;
                MEM_ACC_32: mem_we_outs = {4{client_we}} >> shift_amt_1;
            endcase
        end

        2: begin
            case (client_data_width)
                MEM_ACC_8: client_data_in = mem_data_in >> (8*shift_amt_0);
                MEM_ACC_16, MEM_ACC_32: begin
                    if (prev_mem_cycle == 0)
                        client_data_in = mem_data_in >> (8*shift_amt_0);
                    else
                        client_data_in = client_data_in | mem_data_in >> (8*shift_amt_1);
                end
            endcase
            client_ready = 1'b1;
        end

        3: client_ready = client_request;
    endcase
end

always @ (posedge clk) begin
    if (rst) begin
        mem_cycle <= 0;
        prev_mem_cycle <= 0;
    end else begin
        prev_mem_cycle <= mem_cycle;
        case (mem_cycle)
            0: if (client_request) begin
                case (client_data_width)
                    MEM_ACC_8: mem_cycle <= 2;
                    MEM_ACC_16: mem_cycle <= (shift_amt_0 == 3) ? 1 : 2;
                    MEM_ACC_32: mem_cycle <= (shift_amt_0 == 0) ? 2 : 1;
                endcase
            end

            1: mem_cycle <= 2;

            2: mem_cycle <= 3;

            3: mem_cycle <= client_request ? 3 : 0;
        endcase
    end
end

endmodule
