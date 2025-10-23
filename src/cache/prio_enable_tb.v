`timescale 1ns / 1ps

// Testbench for the priority encoder
module tb_prio_enabler;

    // Parameters for the testbench
    parameter CELL_CNT = 4;
    reg [CELL_CNT-1:0] cmp_results;
    wire [$clog2(CELL_CNT)-1:0] hit_idx;

    // Instantiate the priority encoder
    prio_enabler #(.CELL_CNT(CELL_CNT)) uut (
        .cmp_results(cmp_results),
        .hit_idx(hit_idx)
    );

    // Procedure to display results
    initial begin
        // Monitor the results
        $monitor("Time: %0t | cmp_results: %b | hit_idx: %b", $time, cmp_results, hit_idx);
        //$dumpfile("prio_enabler_tb.vcd");
        //$dumpvars(0, tb_prio_enabler);
        
        // Test cases
        // 1. No input active
        cmp_results = 4'b0000; #10;
        // 2. First input active
        cmp_results = 4'b0001; #10;
        // 3. Second input active
        cmp_results = 4'b0010; #10;
        // 4. Third input active
        cmp_results = 4'b0100; #10;
        // 5. Fourth input active
        cmp_results = 4'b1000; #10;
        // 6. Multiple inputs active (testing priority)
        cmp_results = 4'b1100; #10; // Should output index of highest '1'
        // 7. Change priority
        cmp_results = 4'b0110; #10; // Should output index of highest '1'
        // 8. All inputs active
        cmp_results = 4'b1111; #10; // Should output index of highest '1'
        // 9. All inputs low again
        cmp_results = 4'b0000; #10;
        
        // Finish simulation
        $finish;
    end

endmodule

