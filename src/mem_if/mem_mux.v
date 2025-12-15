module mem_mux
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
    input [M_WIDTH-1:0] mem_data_in,
    input [CLIENT_CNT-1:0] client_requests,
    input [CLIENT_CNT*M_WIDTH-1:0] client_addrs_packed,
    input [CLIENT_CNT-1:0] client_wes,
    input [2*CLIENT_CNT-1:0] client_data_widths_packed,
    input [CLIENT_CNT*M_WIDTH-1:0] client_data_outs_packed,
    input mem_ready,
    output reg mem_request,
    output wire [M_WIDTH*CLIENT_CNT-1:0] client_data_ins_packed,
    output reg [CLIENT_CNT-1:0] client_readies,
    output reg [M_WIDTH-1:0] mem_data_out,
    output reg [M_WIDTH-1:0] mem_addr,
    output reg [1:0] mem_data_width,
    output reg mem_we_out
);

wire [M_WIDTH-1:0] client_addrs [0:CLIENT_CNT-1];
wire [M_WIDTH-1:0] client_data_outs [0:CLIENT_CNT-1];
wire [1:0] client_data_widths [0:CLIENT_CNT-1];
reg [M_WIDTH-1:0] client_data_ins [0:CLIENT_CNT-1];

reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder;
reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder_temp;

genvar i;
generate
    for (i = 0; i < CLIENT_CNT; i = i + 1) begin
        assign client_addrs[i] = client_addrs_packed[M_WIDTH * i +: M_WIDTH];
        assign client_data_outs[i] = client_data_outs_packed[M_WIDTH * i +: M_WIDTH];
        assign client_data_widths[i] = client_data_widths_packed[2*i +: 2];
        assign client_data_ins_packed[M_WIDTH * i +: M_WIDTH] = client_data_ins[i];
    end
endgenerate

reg [1:0] cycle;
integer j;

always @ (*) begin
    if (rst) begin
        mem_request = 0;
        mem_data_out = 0;
        mem_addr = 0;
        mem_data_width = 0;
        mem_we_out = 0;
        client_readies = 0;
        for (j = 0; j < CLIENT_CNT; j = j + 1) begin
            client_data_ins[j] = 0;
        end
        mem_mux_holder_temp = 0;
    end else begin
        mem_mux_holder_temp = 0;
        for (j = 0; j < CLIENT_CNT; j = j + 1) begin
            if (client_requests[j])
                mem_mux_holder_temp = j;
        end

        mem_request = 0;
        mem_data_out = client_data_outs[mem_mux_holder];
        mem_addr = client_addrs[mem_mux_holder];
        mem_data_width = client_data_widths[mem_mux_holder];
        mem_we_out = client_wes[mem_mux_holder];
        client_readies[mem_mux_holder] = mem_ready;
        client_data_ins[mem_mux_holder] = mem_data_in;

        case (cycle)
            0: begin
                if (client_requests) begin
                    mem_data_out = client_data_outs[mem_mux_holder_temp];
                    mem_addr = client_addrs[mem_mux_holder_temp];
                    mem_data_width = client_data_widths[mem_mux_holder_temp];
                    mem_we_out = client_wes[mem_mux_holder_temp];
                    mem_request = 1;
                end
            end

            1: mem_request = 1;

            2: mem_request = client_requests[mem_mux_holder];
        endcase
    end
end

always @ (posedge clk) begin
    if (rst) begin
        mem_mux_holder <= 0;
        cycle <= 0;
    end else begin
        case (cycle)
            0: if (client_requests) begin
                mem_mux_holder <= mem_mux_holder_temp;
                cycle <= 1;
            end
            1: cycle <= mem_ready ? 2 : 1;
            2: cycle <= client_requests[mem_mux_holder] ? 2 : 0;
        endcase
    end
end

endmodule
