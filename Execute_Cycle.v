module execute_cycle(
    clk, rst, 
    RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE,
    ALUControlE, RD1_E, RD2_E, Imm_Ext_E, RD_E,
    PCE, PCPlus4E, 
    funct3E,          
    PCSrcE, PCTargetE,
    RegWriteM, MemWriteM, ResultSrcM,
    RD_M, PCPlus4M, WriteDataM, ALU_ResultM,
    ResultW, ForwardA_E, ForwardB_E
);

    input clk, rst;
    input RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    input [2:0] ALUControlE;
    input [31:0] RD1_E, RD2_E, Imm_Ext_E;
    input [4:0] RD_E;
    input [31:0] PCE, PCPlus4E;
    input [2:0] funct3E;        
    input [31:0] ResultW;
    input [1:0] ForwardA_E, ForwardB_E;

    output PCSrcE;
    output [31:0] PCTargetE;
    output RegWriteM, MemWriteM, ResultSrcM;
    output [4:0] RD_M;
    output [31:0] PCPlus4M, WriteDataM, ALU_ResultM;

    wire [31:0] Src_A, Src_B_interim, Src_B;
    wire [31:0] ResultE;
    wire ZeroE;

    // forwarding mux A
    Mux_3_by_1 srca_mux (
        .a(RD1_E),
        .b(ResultW),
        .c(ALU_ResultM),
        .s(ForwardA_E),
        .d(Src_A)
    );

    // forwarding mux B
    Mux_3_by_1 srcb_mux (
        .a(RD2_E),
        .b(ResultW),
        .c(ALU_ResultM),
        .s(ForwardB_E),
        .d(Src_B_interim)
    );

    // ALU input mux
    Mux alu_src_mux (
        .a(Src_B_interim),
        .b(Imm_Ext_E),
        .s(ALUSrcE),
        .c(Src_B)
    );

    // ALU
    ALU alu (
        .A(Src_A),
        .B(Src_B),
        .Result(ResultE),
        .ALUControl(ALUControlE),
        .OverFlow(),
        .Carry(),
        .Zero(ZeroE),
        .Negative()
    );

    // Branch target
    PC_Adder br_add (
        .a(PCE),
        .b(Imm_Ext_E),
        .c(PCTargetE)
    );

    // core ：real BEQ / BNE decision
    reg branch_taken;

    always @(*) begin
        case (funct3E)
            3'b000: branch_taken = (ZeroE);      // BEQ
            3'b001: branch_taken = (!ZeroE);     // BNE
            default: branch_taken = 1'b0;        // others
        endcase
    end

    assign PCSrcE = BranchE && branch_taken;

    // pipeline registers
    reg RegWriteE_r, MemWriteE_r, ResultSrcE_r;
    reg [4:0] RD_E_r;
    reg [31:0] PCPlus4E_r, RD2_E_r, ResultE_r;

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            RegWriteE_r <= 0;
            MemWriteE_r <= 0;
            ResultSrcE_r <= 0;
            RD_E_r <= 0;
            PCPlus4E_r <= 0;
            RD2_E_r <= 0;
            ResultE_r <= 0;
        end else begin
            RegWriteE_r <= RegWriteE;
            MemWriteE_r <= MemWriteE;
            ResultSrcE_r <= ResultSrcE;
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E;
            RD2_E_r <= Src_B_interim;
            ResultE_r <= ResultE;
        end
    end

    assign RegWriteM = RegWriteE_r;
    assign MemWriteM = MemWriteE_r;
    assign ResultSrcM = ResultSrcE_r;
    assign RD_M = RD_E_r;
    assign PCPlus4M = PCPlus4E_r;
    assign WriteDataM = RD2_E_r;
    assign ALU_ResultM = ResultE_r;

endmodule
