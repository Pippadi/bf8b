module prio_enabler
#(
    parameter CELL_CNT = 4
)
(
    input [CELL_CNT-1:0] cmp_results,
    output wire [$clog2(CELL_CNT)-1:0] hit_idx,
    output reg [0:CELL_CNT-1] enables
);

reg highest_found = 0;
integer i;

genvar j, k;
generate
    assign hit_idx[$clog2(CELL_CNT)-1] = |cmp_results[CELL_CNT-1:CELL_CNT/2];

    for (j = $clog2(CELL_CNT)-2; j >= 0; j = j - 1) begin
        localparam groupsize = 2**j;
        wire grouped[(CELL_CNT/(groupsize*2))-1:0];

        for (k = 0; k < CELL_CNT/(groupsize*2); k = k + 1)
            assign grouped[k] = |cmp_results[groupsize*(1+2*k) +: groupsize];

        assign hit_idx[j] = grouped[hit_idx[$clog2(CELL_CNT)-1:j+1]];
    end
endgenerate

always @ (*) begin
    highest_found = 0;
    enables = {CELL_CNT{1'b1}};

    for (i = 0; i < CELL_CNT; i = i + 1) begin
        if (cmp_results[i] & ~highest_found) begin
            highest_found = 1;
            enables = {CELL_CNT{1'b1}} << (CELL_CNT - 1 - i);
        end
    end
end
endmodule
