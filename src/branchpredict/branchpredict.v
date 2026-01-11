module branch_predictor
#(
    parameter ADDR_WIDTH = 32,
    parameter PREDICT_WIDTH = 2,
    parameter TARGET_CACHE_SIZE = 16,
    parameter DEFAULT_PREDICTION = 2'b10
) (
    input rst,
    input clk,

    // Inputs for making a prediction.
    // `predict_req` is expected to be asserted until `predict_ready` is high.
    input predict_req,
    input [ADDR_WIDTH-1:0] inst_addr_in,
    output reg take,
    output reg predict_ready,

    // Inputs for prediction adjustment after branch resolution.
    // `result_available` is expected to be asserted for one cycle when the
    // branch result is ready. Inputs are latched internally and processed
    // later.
    input result_available,
    input [ADDR_WIDTH-1:0] result_inst_addr,
    input result_taken
);

reg [ADDR_WIDTH-1:0] inst_addr;
wire [PREDICT_WIDTH-1:0] prediction;
wire prediction_cache_hit;
reg prediction_cache_we;
reg result_available_reg, result_taken_reg;
reg [ADDR_WIDTH-1:0] result_inst_addr_reg;

wire [PREDICT_WIDTH-1:0] old_prediction = prediction_cache_hit ? prediction : DEFAULT_PREDICTION;
wire [PREDICT_WIDTH-1:0] new_prediction = result_taken_reg ? (old_prediction == {PREDICT_WIDTH{1'b1}} ? old_prediction : old_prediction + 1) :
    (old_prediction == {PREDICT_WIDTH{1'b0}} ? old_prediction : old_prediction - 1);

cache #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(PREDICT_WIDTH),
    .CELL_CNT(TARGET_CACHE_SIZE)
) PredictionCache (
    .rst(rst),
    .clk(clk),
    .we(prediction_cache_we),
    .addr(inst_addr),
    .data_in(new_prediction),
    .data_out(prediction),
    .hit(prediction_cache_hit)
);

reg [1:0] predict_cycle;
reg [1:0] adjust_cycle;

always @ (posedge clk) begin
    if (rst) begin
        inst_addr <= 0;
        predict_cycle <= 0;
        take <= 0;
        predict_ready <= 0;
        adjust_cycle <= 0;
        prediction_cache_we <= 0;
        result_available_reg <= 0;
        result_taken_reg <= 0;
        result_inst_addr_reg <= 0;
    end else begin
        if (predict_req & (~result_available_reg | predict_cycle != 0)) begin
            case (predict_cycle)
                default: begin
                    inst_addr <= inst_addr_in;
                    predict_cycle <= 1;
                end
                1: begin
                    take <= prediction_cache_hit ? prediction[PREDICT_WIDTH-1] : DEFAULT_PREDICTION[PREDICT_WIDTH-1];
                    predict_cycle <= 2;
                    predict_ready <= 1;
                end
                2: predict_cycle <= predict_req ? 0 : 2;
            endcase
        end else begin
            predict_ready <= 0;
            predict_cycle <= 0;
        end

        if (result_available) begin
            result_available_reg <= 1;
            result_inst_addr_reg <= result_inst_addr;
            result_taken_reg <= result_taken;
        end

        if (result_available_reg & predict_cycle == 0) begin
            case (adjust_cycle)
                0: begin
                    inst_addr <= result_inst_addr_reg;
                    adjust_cycle <= 1;
                end
                1: begin
                    prediction_cache_we <= 1;
                    adjust_cycle <= 2;
                end
                default: begin
                    prediction_cache_we <= 0;
                    adjust_cycle <= 0;
                    result_available_reg <= 0;
                end
            endcase
        end else
            adjust_cycle <= 0;
    end
end

endmodule

