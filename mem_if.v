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
    input [CLIENT_CNT-1:0] requests,
    input [CLIENT_CNT*M_WIDTH-1:0] client_addrs_packed,
    input [CLIENT_CNT-1:0] client_wes,
    input [2*CLIENT_CNT-1:0] client_data_widths_packed,
    input [CLIENT_CNT*M_WIDTH-1:0] client_data_outs_packed,
    output reg [CLIENT_CNT-1:0] client_readies,
    output reg [M_WIDTH-1:0] data_out,
    output reg [M_WIDTH-$clog2(M_WIDTH/8)-1:0] addr,
    output reg [M_WIDTH/8-1:0] we_outs
);

localparam ADDR_WIDTH = M_WIDTH-$clog2(M_WIDTH/8);

reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder;
reg [$clog2(CLIENT_CNT)-1:0] mem_mux_holder_temp;
reg [1:0] mem_cycle;
integer i;

reg [M_WIDTH-1:0] client_addrs [0:CLIENT_CNT-1];
reg [M_WIDTH-1:0] client_data_outs [0:CLIENT_CNT-1];
reg [1:0] client_data_widths [0:CLIENT_CNT-1];

always @ (*) begin
    mem_mux_holder_temp = 0;
    for (i = 0; i < CLIENT_CNT; i = i + 1) begin
        client_addrs[i] = client_addrs_packed[(ADDR_WIDTH-1) * i +: ADDR_WIDTH];
        client_data_outs[i] = client_data_outs_packed[M_WIDTH * i +: M_WIDTH];
        client_data_widths[i] = client_data_widths_packed[2*i +: 2];

        if (requests[i])
            mem_mux_holder_temp = i;
    end
end

always @ (posedge clk) begin
    if (rst) begin
        mem_mux_holder <= 0;
        mem_cycle <= 0;
        client_readies <= 0;
    end else begin
        case (mem_cycle)
            0: if (requests) begin
                mem_mux_holder <= mem_mux_holder_temp;
                addr <= client_addrs[mem_mux_holder_temp][M_WIDTH +: ADDR_WIDTH];
                case (client_data_widths[mem_mux_holder_temp])
                    MEM_ACC_8: begin
                        we_outs <= client_wes[mem_mux_holder_temp] << client_addrs[mem_mux_holder_temp][M_WIDTH-ADDR_WIDTH-1:0];
                        data_out <= client_data_outs[mem_mux_holder_temp] << (8*client_addrs[mem_mux_holder_temp][M_WIDTH-ADDR_WIDTH-1:0]);
                        mem_cycle <= 2;
                    end
                endcase
            end else begin
                mem_mux_holder <= 0;
                we_outs <= 0;
            end

            2: begin
                client_readies[mem_mux_holder] <= 1'b1;
                we_outs <= 0;
                mem_cycle <= 3;
            end

            3: if (~requests[mem_mux_holder]) begin
                client_readies <= 0;
                mem_cycle <= 0;
            end
        endcase
    end
end

endmodule
