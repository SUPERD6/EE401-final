module Main_Decoder(
    input  [6:0] Op,
    output RegWrite,
    output [1:0] ImmSrc,
    output ALUSrc,
    output MemWrite,
    output ResultSrc,
    output Branch,
    output [1:0] ALUOp
);

    assign RegWrite =
           (Op == 7'b0000011) |   // lw
           (Op == 7'b0110011) |   // R-type
           (Op == 7'b0010011);    // I-type

    assign ImmSrc =
           (Op == 7'b0100011) ? 2'b01 :   // S-type
           (Op == 7'b1100011) ? 2'b10 :   // B-type
                                2'b00;   // I-type

    assign ALUSrc =
           (Op == 7'b0000011) |
           (Op == 7'b0100011) |
           (Op == 7'b0010011);

    assign MemWrite = (Op == 7'b0100011);

    assign ResultSrc = (Op == 7'b0000011);

    assign Branch = (Op == 7'b1100011);

    assign ALUOp =
           (Op == 7'b0110011) ? 2'b10 :   // R-type
           (Op == 7'b1100011) ? 2'b01 :   // Branch
                                2'b00;   // Load/Store/I-type

endmodule
