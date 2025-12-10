`include "Fetch_Cycle.v"
`include "Decode_Cyle.v"
`include "Execute_Cycle.v"
`include "Memory_Cycle.v"
`include "Writeback_Cycle.v"    
`include "PC.v"
`include "PC_Adder.v"
`include "Mux.v"
`include "Instruction_Memory.v"
`include "Control_Unit_Top.v"
`include "Register_File.v"
`include "Sign_Extend.v"
`include "ALU.v"
`include "Data_Memory.v"
`include "Hazard_unit.v"

module Pipeline_top(
    input clk,
    input rst
);

    // -----------------------------
    // Inter-stage connections
    // -----------------------------
    wire PCSrcE;

    wire RegWriteE;
    wire ALUSrcE;
    wire MemWriteE;
    wire ResultSrcE;
    wire BranchE;

    wire RegWriteM;
    wire MemWriteM;
    wire ResultSrcM;

    wire RegWriteW;
    wire ResultSrcW;

    wire [2:0] ALUControlE;

    // Register numbers
    wire [4:0] RD_E;
    wire [4:0] RD_M;
    wire [4:0] RDW;
    wire [4:0] RS1_E;
    wire [4:0] RS2_E;

    // Data path
    wire [31:0] PCTargetE;
    wire [31:0] InstrD;
    wire [31:0] PCD;
    wire [31:0] PCPlus4D;

    wire [31:0] RD1_E;
    wire [31:0] RD2_E;
    wire [31:0] Imm_Ext_E;
    wire [31:0] PCE;
    wire [31:0] PCPlus4E;

    wire [31:0] PCPlus4M;
    wire [31:0] WriteDataM;
    wire [31:0] ALU_ResultM;

    wire [31:0] PCPlus4W;
    wire [31:0] ALU_ResultW;
    wire [31:0] ReadDataW;
    wire [31:0] ResultW;

    // Forwarding control
    wire [1:0] ForwardAE;
    wire [1:0] ForwardBE;
    wire [2:0] funct3E;
    // -----------------------------
    // Fetch phase
    // -----------------------------
    fetch_cycle u_fetch (
        .clk       (clk),
        .rst       (rst),
        .PCSrcE    (PCSrcE),
        .PCTargetE (PCTargetE),
        .InstrD    (InstrD),
        .PCD       (PCD),
        .PCPlus4D  (PCPlus4D)
    );

    // -----------------------------
    // Decode phase
    // -----------------------------
    decode_cycle u_decode (
    .clk        (clk),
    .rst        (rst),

    .InstrD     (InstrD),
    .PCD        (PCD),
    .PCPlus4D   (PCPlus4D),

    // WB Stage feedback
    .RegWriteW  (RegWriteW),
    .RDW        (RDW),
    .ResultW    (ResultW),

    // Outputs to Execute stage
    .RegWriteE  (RegWriteE),
    .ALUSrcE    (ALUSrcE),
    .MemWriteE  (MemWriteE),
    .ResultSrcE (ResultSrcE),
    .BranchE    (BranchE),
    .ALUControlE(ALUControlE),

    // Operand & immediate forwarding
    .RD1_E      (RD1_E),
    .RD2_E      (RD2_E),
    .Imm_Ext_E  (Imm_Ext_E),
    .RD_E       (RD_E),

    .PCE        (PCE),
    .PCPlus4E   (PCPlus4E),

    // New signals ( MUST MATCH decode module )
    .RS1_E      (RS1_E),
    .RS2_E      (RS2_E)
    );


    // -----------------------------
    // Execute phase
    // -----------------------------
    execute_cycle u_execute (
        .clk         (clk),
        .rst         (rst),
        .RegWriteE   (RegWriteE),
        .ALUSrcE     (ALUSrcE),
        .MemWriteE   (MemWriteE),
        .ResultSrcE  (ResultSrcE),
        .BranchE     (BranchE),
        .ALUControlE (ALUControlE),
        .RD1_E       (RD1_E),
        .RD2_E       (RD2_E),
        .Imm_Ext_E   (Imm_Ext_E),
        .RD_E        (RD_E),
        .PCE         (PCE),
        .PCPlus4E    (PCPlus4E),
        .ResultW     (ResultW),
        .ForwardA_E  (ForwardAE),
        .ForwardB_E  (ForwardBE),
        .PCSrcE      (PCSrcE),
        .RegWriteM   (RegWriteM),
        .MemWriteM   (MemWriteM),
        .ResultSrcM  (ResultSrcM),
        .RD_M        (RD_M),
        .PCPlus4M    (PCPlus4M),
        .WriteDataM  (WriteDataM),
        .ALU_ResultM (ALU_ResultM),
        .PCTargetE   (PCTargetE)
        
    );
    // -----------------------------
    // Memory phase
    // -----------------------------
    memory_cycle u_memory (
        .clk         (clk),
        .rst         (rst),
        .RegWriteM   (RegWriteM),
        .MemWriteM   (MemWriteM),
        .ResultSrcM  (ResultSrcM),
        .RD_M        (RD_M),
        .PCPlus4M    (PCPlus4M),
        .WriteDataM  (WriteDataM),
        .ALU_ResultM (ALU_ResultM),
        .RegWriteW   (RegWriteW),
        .ResultSrcW  (ResultSrcW),
        .RD_W        (RDW),
        .PCPlus4W    (PCPlus4W),
        .ALU_ResultW (ALU_ResultW),
        .ReadDataW   (ReadDataW)
    );

    // -----------------------------
    // Writeback phase
    // -----------------------------
    writeback_cycle u_writeback (
        .clk        (clk),
        .rst        (rst),
        .ResultSrcW (ResultSrcW),
        .PCPlus4W   (PCPlus4W),
        .ALU_ResultW(ALU_ResultW),
        .ReadDataW  (ReadDataW),
        .ResultW    (ResultW)
    );

    // -----------------------------
    // Hazard / Forwarding unit
    // -----------------------------
    hazard_unit u_hazard (
        .rst       (rst),
        .RegWriteM (RegWriteM),
        .RegWriteW (RegWriteW),
        .RD_M      (RD_M),
        .RD_W      (RDW),
        .Rs1_E     (RS1_E),
        .Rs2_E     (RS2_E),
        .ForwardAE (ForwardAE),
        .ForwardBE (ForwardBE)
    );

endmodule
