module fetch_cycle(
    input        clk,
    input        rst,
    input        PCSrcE,
    input [31:0] PCTargetE,
    output [31:0] InstrD,
    output [31:0] PCD,
    output [31:0] PCPlus4D
);

    // PC register + next PC
    wire [31:0] PCF;
    wire [31:0] PCNext;
    wire [31:0] PCPlus4F;
    wire [31:0] InstrF;

    // Avoid X propagation: only consider PCSrcE valid when it is truly 1
    wire PCSrcE_safe = (PCSrcE === 1'b1) ? 1'b1 : 1'b0;

    // Next PC: if branch in EX stage is taken, use target address; otherwise, PC+4 for sequential execution
    assign PCNext = PCSrcE_safe ? PCTargetE : PCPlus4F;

    // Program Counter
    PC_Module u_pc (
        .clk     (clk),
        .rst     (rst),
        .PC      (PCF),
        .PC_Next (PCNext)
    );

    // PC + 4
    PC_Adder u_pc_adder (
        .a (PCF),
        .b (32'h0000_0004),
        .c (PCPlus4F)
    );

    // Instruction memory
    Instruction_Memory u_imem (
        .rst (rst),
        .A   (PCF),
        .RD  (InstrF)
    );

    // IF/ID pipeline registers
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg;
    reg [31:0] PCPlus4F_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            InstrF_reg    <= 32'h0000_0000;
            PCF_reg       <= 32'h0000_0000;
            PCPlus4F_reg  <= 32'h0000_0000;
        end else begin
            InstrF_reg    <= InstrF;
            PCF_reg       <= PCF;
            PCPlus4F_reg  <= PCPlus4F;
        end
        $display("TIME=%0t  PCF=%h  InstrF=%h", $time, PCF, InstrF);
    end

    // Outputs to Decode phase
    assign InstrD   = rst ? InstrF_reg    : 32'h0000_0000;
    assign PCD      = rst ? PCF_reg       : 32'h0000_0000;
    assign PCPlus4D = rst ? PCPlus4F_reg  : 32'h0000_0000;

endmodule
