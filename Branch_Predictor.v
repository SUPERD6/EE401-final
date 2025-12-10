module Branch_Predictor #(
    parameter INDEX_BITS = 4
)(
    input        clk,
    input        rst,

    // Fetch 阶段：根据当前 PCF 做预测
    input  [31:0] PCF,
    output        predict_takenF,
    output [31:0] predict_targetF,

    // Execute 阶段：真实分支结果，用来更新表
    input         branchE,        // 这一拍是不是分支指令
    input         actual_takenE,  // = PCSrcE
    input  [31:0] PCE,            // 分支指令自己的 PC
    input  [31:0] actual_targetE  // 真正跳转目标 = PCTargetE
);
    localparam BHT_SIZE = 1 << INDEX_BITS;

    reg         bht [0:BHT_SIZE-1];   // 1-bit 历史：0=not taken,1=taken
    reg [31:0]  btb [0:BHT_SIZE-1];   // 记录目标地址

    wire [INDEX_BITS-1:0] idxF = PCF[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] idxE = PCE[INDEX_BITS+1:2];

    integer i;

    // 初始化
    initial begin
        for (i = 0; i < BHT_SIZE; i = i + 1) begin
            bht[i] = 1'b0;           // 初始全预测 not taken
            btb[i] = 32'b0;
        end
    end

    // 取预测：在 Fetch 阶段使用
    assign predict_takenF  = bht[idxF];
    assign predict_targetF = btb[idxF];

    // 更新策略：在 EX 阶段拿真实结果修正表
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                bht[i] <= 1'b0;
                btb[i] <= 32'b0;
            end
        end else if (branchE) begin
            // 更新预测位
            bht[idxE] <= actual_takenE;
            // 如果实际 taken，更新 BTB 目标
            if (actual_takenE)
                btb[idxE] <= actual_targetE;
        end
    end

endmodule
