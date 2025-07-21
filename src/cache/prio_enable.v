module prio_enabler
#(
    parameter CELL_CNT = 4
)
(
    input [0:CELL_CNT-1] cmp_results,
    output reg [$clog2(CELL_CNT)-1:0] hit_idx,
    output reg [0:CELL_CNT-1] enables
);

reg highest_found = 0;
integer i;

always @ (*) begin
    hit_idx = 0;
    highest_found = 0;
    enables = {CELL_CNT{1'b1}};

    for (i = 0; i < CELL_CNT; i = i + 1) begin
        if (cmp_results[i] & ~highest_found) begin
            highest_found = 1;
            hit_idx = i[$clog2(CELL_CNT)-1:0];
            enables = {CELL_CNT{1'b1}} << (CELL_CNT - 1 - i);
        end
    end
end
endmodule
