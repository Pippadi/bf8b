`default_nettype none

module eightbit(
    input reg clk,
    input reg [7:0] data_in,
    output reg [7:0] addr,
    output reg [7:0] data_out,
    output reg we
    );

    reg [7:0] a, b, pc, inst, pipe;

    initial begin
        a = 8'h00;
        b = 8'h00;
        pc = 8'h00;
        inst = 8'h00;
        pipe = 8'h00;
        we = 1'b0;
        addr = pc;
    end

    always @ (posedge clk) begin
        case (pipe)
            8'h00: begin
                inst = data_in;
                pipe = 8'h01;
            end
            8'h01: begin
                case (inst)
                    // Move word at address in pc + 0x01 to a
                    8'h01: begin
                        addr[7:0] = pc[7:0] + 8'h01;
                        we = 0;
                    end

                    // Move a to address at pc + 0x01
                    8'h02: begin
                        addr[7:0] = pc[7:0] + 8'h01;
                        we = 1;
                        data_out[7:0] = a[7:0];
                    end
                    // Move pc to a.
                    8'h03: a[7:0] = pc[7:0];

                    // Move a to pc.
                    8'h04: pc[7:0] = a[7:0];

                    // Move b to a.
                    8'h05: a[7:0] = b[7:0];

                    // Move a to b.
                    8'h06: b[7:0] = a[7:0];

                    8'h10: a = a + b;
                    8'h11: a = a - b;
                    8'h12: a = a * b;
                    8'h13: a = a / b;
                    8'h14: a = a & b;
                    8'h15: a = a | b;
                    8'h16: a = a ^ b;
                    8'h17: a = ~a;

                    default: ;
                endcase
                pipe = 8'h02;
            end
            8'h02: begin
                // Move word at pc + 0x01 to a
                if (inst[7:0] == 8'h01)
                    a[7:0] = data_in[7:0];

                pipe[7:0] = 8'b00;
                we = 0;
                pc[7:0] = pc[7:0] + 8'h01;
            end
        endcase
    end
    endmodule
