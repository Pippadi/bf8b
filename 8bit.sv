`default_nettype none

module eightbit(
    input clk,
    input [7:0] data_in,
    output [7:0] addr,
    output [7:0] data_out,
    output write_en,
    output memclk
    );

    reg [7:0] a, b, pc, inst;

    always @ (posedge clk) begin
        addr <= pc[7:0];
        write_en <= 0;
        memclk <= 1;
        inst[7:0] = data_in[7:0];
        case (inst)
            // Move byte at address pc + 0x01 to a.
            8'h01: a[7:0] = mem[pc[7:0] + 8'h1][7:0];

            // Move byte from a to address in pc + 0x01.
            8'h02:
            if (pc[7:0] <= 8'hfe)
                mem[pc[7:0] + 8'h1] = a[7:0];

            // Move pc to a.
            8'h03: a[7:0] = pc[7:0];

            // Move a to pc.
            8'h04: pc = a;

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
            8'h17: a[7:0] = ~a[7:0];

            default: ;
        endcase

        if (pc == 8'h1 || pc == 8'h2 || pc == 8'h3)
            pc[7:0] = pc[7:0] + 8'd2;
        else
            pc[7:0] = pc[7:0] + 8'd1;
    end
    endmodule
