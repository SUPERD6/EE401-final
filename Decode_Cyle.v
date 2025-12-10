module decode_cycle(
    input clk,
    input rst,
    input [31:0] InstrD,
    input [31:0] PCD,
    input [31:0] PCPlus4D,

    input RegWriteW,
    input [4:0] RDW,
    input [31:0] ResultW,

    output RegWriteE,
    output ALUSrcE,
    output MemWriteE,
    output ResultSrcE,
    output BranchE,
    output [2:0] ALUControlE,

    output [31:0] RD1_E,
    output [31:0] RD2_E,
    output [31:0] Imm_Ext_E,
    output [4:0]  RD_E,

    output [31:0] PCE,
    output [31:0] PCPlus4E,

    output [4:0] RS1_E,
    output [4:0] RS2_E
);

    // ===============================
    // Instruction Fields
    // ===============================
    wire [6:0] opcode = InstrD[6:0];
    wire [4:0] rd     = InstrD[11:7];
    wire [2:0] funct3 = InstrD[14:12];
    wire [4:0] rs1    = InstrD[19:15];
    wire [4:0] rs2    = InstrD[24:20];
    wire [6:0] funct7 = InstrD[31:25];

    assign RS1_E = rs1;
    assign RS2_E = rs2;

    // ===============================
    // Main Control Decoder
    // ===============================
    wire RegWriteD;
    wire [1:0] ImmSrc;
    wire ALUSrcD;
    wire MemWriteD;
    wire ResultSrcD;
    wire BranchD;
    wire [1:0] ALUOp;

    Main_Decoder main_dec (
        .Op(opcode),
        .RegWrite(RegWriteD),
        .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrcD),
        .MemWrite(MemWriteD),
        .ResultSrc(ResultSrcD),
        .Branch(BranchD),
        .ALUOp(ALUOp)
    );

    // ===============================
    // ALU Decoder
    // ===============================
    wire [2:0] ALUControlD;

    ALU_Decoder alu_dec (
        .funct3(funct3),
        .funct7(funct7),
        .ALUOp(ALUOp),
        .ALUControl(ALUControlD)
    );

    // ===============================
    // Register File
    // ===============================
    wire [31:0] RD1_D;
    wire [31:0] RD2_D;

    Register_File rf (
        .clk(clk),
        .rst(rst),
        .WE3(RegWriteW),
        .A1(rs1),
        .A2(rs2),
        .A3(RDW),
        .WD3(ResultW),
        .RD1(RD1_D),
        .RD2(RD2_D)
    );

    wire [31:0] Imm_Ext_D;

    Sign_Extend imm_ext (
        .In(InstrD),
        .ImmSrc(ImmSrc),
        .Imm_Ext(Imm_Ext_D)
    );

    // ===============================
    // Pipeline Registers (D → E)
    // ===============================
    reg RegWriteD_r, ALUSrcD_r, MemWriteD_r, ResultSrcD_r, BranchD_r;
    reg [2:0] ALUControlD_r;
    reg [31:0] RD1_D_r, RD2_D_r, Imm_Ext_D_r;
    reg [4:0] rd_r;
    reg [31:0] PCD_r, PCPlus4D_r;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            RegWriteD_r   <= 0;
            ALUSrcD_r     <= 0;
            MemWriteD_r   <= 0;
            ResultSrcD_r  <= 0;
            BranchD_r     <= 0;
            ALUControlD_r <= 0;
            RD1_D_r       <= 0;
            RD2_D_r       <= 0;
            Imm_Ext_D_r   <= 0;
            rd_r          <= 0;
            PCD_r         <= 0;
            PCPlus4D_r    <= 0;
        end else begin
            RegWriteD_r   <= RegWriteD;
            ALUSrcD_r     <= ALUSrcD;
            MemWriteD_r   <= MemWriteD;
            ResultSrcD_r  <= ResultSrcD;
            BranchD_r     <= BranchD;
            ALUControlD_r <= ALUControlD;
            RD1_D_r       <= RD1_D;
            RD2_D_r       <= RD2_D;
            Imm_Ext_D_r   <= Imm_Ext_D;
            rd_r          <= rd;
            PCD_r         <= PCD;
            PCPlus4D_r    <= PCPlus4D;
        end
    end

    // ===============================
    // Outputs to Execute Stage
    // ===============================
    assign RegWriteE   = RegWriteD_r;
    assign ALUSrcE     = ALUSrcD_r;
    assign MemWriteE   = MemWriteD_r;
    assign ResultSrcE  = ResultSrcD_r;
    assign BranchE     = BranchD_r;
    assign ALUControlE= ALUControlD_r;
    assign RD1_E       = RD1_D_r;
    assign RD2_E       = RD2_D_r;
    assign Imm_Ext_E   = Imm_Ext_D_r;
    assign RD_E        = rd_r;
    assign PCE         = PCD_r;
    assign PCPlus4E    = PCPlus4D_r;

endmodule
