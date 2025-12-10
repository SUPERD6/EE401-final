module tb;

    // =========================
    // 0. All registers / variable declarations
    // =========================

    reg clk;
    reg rst;

    // Performance statistics
    integer cycle_count;
    integer commit_count;
    integer first_commit_cycle;
    integer last_commit_cycle;
    integer active_cycles;

    real CPI_total;
    real IPC_total;
    real CPI_active;
    real IPC_active;

    // Branch prediction statistics
    integer branch_total;
    integer branch_taken;
    integer branch_correct;

    real branch_acc;
    real branch_miss_rate;

    // Decode / Execute phase branch-related signals (shadowed in testbench)
    reg [6:0]  opcode_D;
    reg        is_branch_D;
    reg [31:0] imm_branch_D;
    reg        predict_taken_D;

    reg        is_branch_E;
    reg        predict_taken_E;
    reg        actual_taken_E;

    initial begin
        clk = 0;
        rst = 0;

        cycle_count        = 0;
        commit_count       = 0;
        first_commit_cycle = 0;
        last_commit_cycle  = 0;

        branch_total       = 0;
        branch_taken       = 0;
        branch_correct     = 0;

        #100;
        rst = 1;
    end

    // =========================
    // 2. Clock
    // =========================
    always #50 clk = ~clk;

    // =========================
    // 3. DUT instantiation
    // =========================
    Pipeline_top dut (
        .clk(clk),
        .rst(rst)
    );

    // =========================
    // 4. VCD waveform
    // =========================
    initial begin
        $dumpfile("dump_final.vcd");
        $dumpvars(0, tb);
    end

    // =========================
    // 5. Cycle counting
    // =========================
    always @(posedge clk) begin
        if (rst)
            cycle_count = cycle_count + 1;
    end

    // =========================
    // 6. Write-back (commit) monitoring
    // =========================
    always @(posedge clk) begin
        if (rst && dut.RegWriteW) begin

            if (commit_count == 0)
                first_commit_cycle = cycle_count;

            last_commit_cycle = cycle_count;
            commit_count      = commit_count + 1;

            $display("WB Commit @ %0t ns : cycle=%0d  RDW=%0d  ResultW=%0d",
                     $time, cycle_count, dut.RDW, dut.ResultW);
        end
    end

    // =========================
    // 7. Decode phase: branch prediction (BTFNT)
    // =========================
    always @(posedge clk) begin
        if (rst) begin
            // extract opcode
            opcode_D    <= dut.InstrD[6:0];
            is_branch_D <= (dut.InstrD[6:0] == 7'b1100011);  // BEQ/BNE/BLT...

            // build B-type immediate (sign-extended)
            imm_branch_D <= { {20{dut.InstrD[31]}},
                              dut.InstrD[7],
                              dut.InstrD[30:25],
                              dut.InstrD[11:8],
                              1'b0 };

            //  BTFNT: backward taken, forward not taken
            predict_taken_D <= is_branch_D && imm_branch_D[31];

            is_branch_E     <= is_branch_D;
            predict_taken_E <= predict_taken_D;
            actual_taken_E  <= dut.PCSrcE;  // if actually taken
        end
    end

    always @(posedge clk) begin
        if (rst && is_branch_E) begin
            branch_total = branch_total + 1;

            if (actual_taken_E)
                branch_taken = branch_taken + 1;

            // predict correct 
            if ( (predict_taken_E && actual_taken_E) ||
                 (!predict_taken_E && !actual_taken_E) )
                branch_correct = branch_correct + 1;
        end
    end

    // =========================
    // 9. end of simulation 
    // =========================
    initial begin
        #20000;

        if (commit_count == 0) begin
            $display("====================================");
            $display("  WARNING: no instruction committed");
            $display("====================================");
        end else begin
            active_cycles = last_commit_cycle - first_commit_cycle + 1;

            CPI_total  = cycle_count * 1.0 / commit_count;
            IPC_total  = commit_count * 1.0 / cycle_count;

            CPI_active = active_cycles * 1.0 / commit_count;
            IPC_active = commit_count * 1.0 / active_cycles;

            if (branch_total > 0) begin
                branch_acc      = branch_correct * 1.0 / branch_total;
                branch_miss_rate= 1.0 - branch_acc;
            end else begin
                branch_acc      = 0.0;
                branch_miss_rate= 0.0;
            end

            $display("====================================");
            $display("   Correct Performance Evaluation");
            $display("====================================");
            $display("Total cycles (reset->end)      = %0d", cycle_count);
            $display("Committed instructions         = %0d", commit_count);
            $display("First commit cycle             = %0d", first_commit_cycle);
            $display("Last  commit cycle             = %0d", last_commit_cycle);
            $display("------------------------------------");
            $display("CPI_total (with tail)          = %0f", CPI_total);
            $display("IPC_total (with tail)          = %0f", IPC_total);
            $display("------------------------------------");
            $display("CPI_active (commit window)     = %0f", CPI_active);
            $display("IPC_active (commit window)     = %0f", IPC_active);
            $display("------------------------------------");
            $display("Total branches                 = %0d", branch_total);
            $display("Taken branches                 = %0d", branch_taken);
            $display("Correct predictions            = %0d", branch_correct);
            $display("Branch prediction accuracy     = %0f", branch_acc);
            $display("Branch misprediction rate      = %0f", branch_miss_rate);
            $display("====================================");
        end

        $finish;
    end

endmodule
