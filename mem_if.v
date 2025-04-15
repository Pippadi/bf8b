module mem_if (
    input rst,
    input clk,
    input [7:0] data_in,
    input exec_mem_req,
    input [7:0] exec_mem_addr,
    input exec_mem_we,
    input [7:0] exec_data_out,
    input fetch_mem_req,
    input [7:0] fetch_addr,
    output reg [7:0] data_out,
    output reg [7:0] addr,
    output reg exec_mem_ready,
    output reg fetch_mem_ready,
    output reg we
);

// For whether the exec stage is holding the memory bus
reg mem_mux_exec;
reg [1:0] mem_cycle;

always @ (posedge clk) begin
    if (rst) begin
        mem_mux_exec <= 0;
        mem_cycle <= 0;
    end else begin
        case (mem_cycle)
            0: begin
                if (exec_mem_req || fetch_mem_req) begin
                    addr <= exec_mem_req ? exec_mem_addr : fetch_addr;
                    we <= exec_mem_req ? exec_mem_we : 0;
                    mem_mux_exec = exec_mem_req;
                    data_out <= exec_data_out;
                    exec_mem_ready <= 0;
                    fetch_mem_ready <= 0;
                    mem_cycle <= 1;
                end else begin
                    mem_cycle <= 0;
                    mem_mux_exec <= 0;
                    we <= 0;
                    fetch_mem_ready <= 0;
                    exec_mem_ready <= 0;
                end
            end
            1: begin
                if (mem_mux_exec)
                    exec_mem_ready <= 1;
                else
                    fetch_mem_ready <= 1;
                we <= 0;
                mem_cycle <= 2;
            end
            2: begin
                if ((mem_mux_exec & ~exec_mem_req) | (~mem_mux_exec & ~fetch_mem_req)) begin
                    exec_mem_ready <= 0;
                    fetch_mem_ready <= 0;
                    mem_cycle <= 0;
                end
            end
        endcase
    end
end

endmodule
