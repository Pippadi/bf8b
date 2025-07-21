module prio_enabler
#(
    parameter CELL_CNT = 4
)
(
    input [0:CELL_CNT-1] cmp_results,
    output reg [0:CELL_CNT-1] enables
);

reg highest_prio_found;
integer i;
always @ (*) begin
    enables = {CELL_CNT{1'b1}};
    highest_prio_found = 0;

    for (i = 0; i < CELL_CNT; i = i + 1) begin
        if (cmp_results[i] & ~highest_prio_found) begin
            highest_prio_found = 1;
            enables = {CELL_CNT{1'b1}} << (CELL_CNT-i-1);
        end
    end
end
endmodule

