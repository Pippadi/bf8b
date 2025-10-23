module prio_enabler
#(
    parameter CELL_CNT = 4
)
(
    input [CELL_CNT-1:0] cmp_results,
    output wire [$clog2(CELL_CNT)-1:0] hit_idx,
    output wire [CELL_CNT-1:0] enables
);

genvar i, j, k;
generate
    assign hit_idx[$clog2(CELL_CNT)-1] = |cmp_results[CELL_CNT-1:CELL_CNT/2];

    for (j = $clog2(CELL_CNT)-2; j >= 0; j = j - 1) begin
        localparam groupsize = 2**j;
        wire grouped[(CELL_CNT/(groupsize*2))-1:0];

        for (k = 0; k < CELL_CNT/(groupsize*2); k = k + 1)
            assign grouped[k] = |cmp_results[groupsize*(1+2*k) +: groupsize];

        assign hit_idx[j] = grouped[hit_idx[$clog2(CELL_CNT)-1:j+1]];
    end

    assign enables = |cmp_results ? {CELL_CNT{1'b1}} >> (CELL_CNT - 1 - hit_idx) : {CELL_CNT{1'b1}};
endgenerate

endmodule
