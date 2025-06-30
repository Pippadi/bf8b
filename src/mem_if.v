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
    input [M_WIDTH-1:0] data_in,
    input [CLIENT_CNT-1:0] requests,
    input [CLIENT_CNT*M_WIDTH-1:0] client_addrs_packed,
    input [CLIENT_CNT-1:0] client_wes,
    input [2*CLIENT_CNT-1:0] client_data_widths_packed,
    input [CLIENT_CNT*M_WIDTH-1:0] client_data_outs_packed,
    output reg [M_WIDTH*CLIENT_CNT-1:0] client_data_ins_packed,
    output reg [CLIENT_CNT-1:0] client_readies,
    output reg [M_WIDTH-1:0] data_out,
    output reg [M_WIDTH-$clog2(M_WIDTH/8)-1:0] addr,
    output reg [M_WIDTH/8-1:0] we_outs
);

localparam BANK_SEL_WIDTH = $clog2(M_WIDTH/8);
localparam ADDR_WIDTH = M_WIDTH-BANK_SEL_WIDTH;

reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder;
reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder_temp;
reg [1:0] mem_cycle;
reg [1:0] prev_mem_cycle;
integer i;

reg [M_WIDTH-1:0] client_addrs [0:CLIENT_CNT-1];
reg [M_WIDTH-1:0] client_data_outs [0:CLIENT_CNT-1];
reg [M_WIDTH-1:0] client_data_ins [0:CLIENT_CNT-1];
reg [1:0] client_data_widths [0:CLIENT_CNT-1];

reg [BANK_SEL_WIDTH-1:0] shift_amt_temp;
reg [BANK_SEL_WIDTH-1:0] shift_amt_0;
reg [BANK_SEL_WIDTH-1:0] shift_amt_1;

always @ (*) begin
    mem_mux_holder_temp = 0;
    for (i = 0; i < CLIENT_CNT; i = i + 1) begin
        client_addrs[i] = client_addrs_packed[M_WIDTH * i +: M_WIDTH];
        client_data_outs[i] = client_data_outs_packed[M_WIDTH * i +: M_WIDTH];
        client_data_widths[i] = client_data_widths_packed[2*i +: 2];
        client_data_ins_packed[M_WIDTH * i +: M_WIDTH] = client_data_ins[i];

        if (requests[i])
            mem_mux_holder_temp = i;
    end

    we_outs = 0;
    shift_amt_temp = client_addrs[mem_mux_holder_temp][BANK_SEL_WIDTH-1:0];
    client_readies = 0;
    case (mem_cycle)
        0: if (requests) begin
            shift_amt_0 = shift_amt_temp;
            shift_amt_1 = ~shift_amt_0 + 1;
            addr = client_addrs[mem_mux_holder_temp][M_WIDTH-1:BANK_SEL_WIDTH];
            data_out = client_data_outs[mem_mux_holder_temp] << (8*shift_amt_0);

            case (client_data_widths[mem_mux_holder_temp])
                MEM_ACC_8: we_outs = client_wes[mem_mux_holder_temp] << shift_amt_0;
                MEM_ACC_16: we_outs = {2{client_wes[mem_mux_holder_temp]}} << shift_amt_0;
                MEM_ACC_32: we_outs = {4{client_wes[mem_mux_holder_temp]}} << shift_amt_0;
            endcase
        end

        1: begin
            addr = client_addrs[mem_mux_holder][M_WIDTH-1:BANK_SEL_WIDTH] + 1;
            data_out = client_data_outs[mem_mux_holder] << (8*shift_amt_1);
            client_data_ins[mem_mux_holder] = data_in >> (8*shift_amt_0);
            case (client_data_widths[mem_mux_holder_temp])
                MEM_ACC_16: we_outs = {2{client_wes[mem_mux_holder]}} >> shift_amt_1;
                MEM_ACC_32: we_outs = {4{client_wes[mem_mux_holder]}} >> shift_amt_1;
            endcase
        end

        2: begin
            case (client_data_widths[mem_mux_holder])
                MEM_ACC_8: client_data_ins[mem_mux_holder] = data_in >> (8*shift_amt_0);
                MEM_ACC_16, MEM_ACC_32: begin
                    if (prev_mem_cycle == 0)
                        client_data_ins[mem_mux_holder] = data_in >> (8*shift_amt_0);
                    else
                        client_data_ins[mem_mux_holder] = client_data_ins[mem_mux_holder] | data_in >> (8*shift_amt_1);
                end
            endcase
            client_readies[mem_mux_holder] = 1'b1;
        end

        3: client_readies[mem_mux_holder] = requests[mem_mux_holder];
    endcase
end

always @ (posedge clk) begin
    if (rst) begin
        mem_mux_holder <= 0;
        mem_cycle <= 0;
        prev_mem_cycle <= 0;
    end else begin
        prev_mem_cycle <= mem_cycle;
        case (mem_cycle)
            0: if (requests) begin
                mem_mux_holder <= mem_mux_holder_temp;
                case (client_data_widths[mem_mux_holder_temp])
                    MEM_ACC_8: mem_cycle <= 2;
                    MEM_ACC_16: mem_cycle <= (shift_amt_0 == 3) ? 1 : 2;
                    MEM_ACC_32: mem_cycle <= (shift_amt_0 == 0) ? 2 : 1;
                endcase
            end

            1: mem_cycle <= 2;

            2: mem_cycle <= 3;

            3: mem_cycle <= requests[mem_mux_holder] ? 3 : 0;
        endcase
    end
end

endmodule
