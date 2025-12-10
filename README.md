# RISC-V-32I-5-Stage-Pipeline-Core
**5-stage pipelined implementation of a RISC-V 32I processor with dynamic branch prediction optimization.**

This repository contains a 5-stage pipelined processor implementation of the RISC-V 32I ISA.  
This work is an extended version of the original single-cycle implementation provided by:

👉 Original Single-Cycle Core:  
[https://github.com/Varunkumar0610/RISC-V-Single-Cycle-Core  ](https://github.com/Varunkumar0610/RISC-V-32I-5-stage-Pipeline-Core)

Based on the original design, this project further extends the processor with:

- A fully functional 5-stage pipeline (IF, ID, EX, MEM, WB)
- Data hazard handling using forwarding
- **Dynamic 1-bit branch prediction (BHT + BTB)**
- **Automatic CPI / IPC performance evaluation testbench**
- **Baseline vs Optimized pipeline performance comparison**

---

## 📌 Pipeline Stages Overview

In a 5-stage pipelined processor, each instruction is divided into the following stages:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Instruction Execution (EX)
- Memory Read/Write (MEM)
- Write Back (WB)

This pipelined architecture improves throughput by overlapping multiple instructions in different stages.

---

## ✅ Supported Instruction Types

This RISC-V 5-stage pipeline supports the following basic instruction formats:

- R-Type  
- I-Type  
- S-Type  
- B-Type  
- J-Type  
- U-Type  

---

## ⚠️ Hazard Handling

This pipelined implementation encounters hazards, which are handled using a dedicated **hazard unit**.

### Types of Hazards

### 1. Structural Hazard
- Occurs when hardware cannot support two operations in the same clock cycle.
- A single shared memory can cause a structural hazard.

### 2. Data Hazard
- Occurs when data is not yet available for an instruction.
- Solved using:
  - Forwarding / bypassing
  - Pipeline stalling (NOPs if required)

✅ In this design, **data hazards are resolved using forwarding / bypassing**.

### 3. Control Hazard
- Occurs due to branch instructions.
- **This project extends the baseline design with a dynamic branch predictor to reduce control hazards.**

---

## 🧠 Dynamic Branch Prediction (Newly Added Feature)

To reduce control hazard penalties, a **1-bit dynamic branch predictor** is integrated into the pipeline.

### Predictor Components

- **Branch History Table (BHT)**  
  - Stores 1-bit prediction per entry  
  - `0`: Not Taken  
  - `1`: Taken  

- **Branch Target Buffer (BTB)**  
  - Stores the most recent branch target address  

### Predictor Behavior

- Prediction is performed in the **Fetch (IF) stage**
- Predictor update is performed in the **Execute (EX) stage**
- Indexed using low-order bits of the PC
- The predictor learns loop behavior dynamically

This mechanism allows the Fetch stage to **speculatively jump early**, reducing wrong-path instruction fetches and improving pipeline efficiency.

---

## 🧪 Automatic Performance Evaluation (Newly Added Feature)

The original baseline testbench only supported functional verification.  
This project introduces a **performance-aware testbench** that automatically computes:

- Total cycle count
- Committed instruction count (via `RegWriteW`)
- CPI (total and active window)
- IPC (total and active window)
- Branch count
- Correct predictions
- Branch prediction accuracy

⚠️ Since store and pure branch instructions do not write registers, committed instructions are approximated using `RegWriteW`.  
This slightly underestimates total architectural instruction count but is sufficient for **relative CPI/IPC comparison**.

---

## 🧪 Baseline vs Optimized Pipeline Comparison

For branch-intensive loop benchmarks:

- The **baseline pipeline** suffers from repeated wrong-path instruction fetches because branch resolution happens only in EX stage.
- The **optimized pipeline** quickly learns loop behavior using the branch predictor and avoids wrong-path execution.

This leads to:

- Reduced CPI
- Increased IPC
- Higher branch prediction accuracy
- Elimination of wrong-path instruction commits

---

## 🏗️ Implementation and Datapath

The pipelined implementation introduces a series of **pipeline registers between all stages**.  
Each instruction is propagated through:

- IF/ID  
- ID/EX  
- EX/MEM  
- MEM/WB  

This follows an extended version of the original single-cycle datapath.

**Pipeline Datapath Overview:**

![block diagram](https://github.com/user-attachments/assets/42f3b097-bc33-449c-b613-3b0cdca62cc9)

---

## 🧩 Discussion of Pipeline Stages

### 1. Fetch Cycle Datapath
The Fetch stage retrieves the next instruction from instruction memory.  
With branch prediction enabled, it selects the next PC using:

- Predicted target from the branch predictor  
- Or corrected target from EX stage on misprediction  

---

### 2. Decode Cycle Datapath
The Decode stage interprets the instruction and generates control signals.  
Register operands are read, and immediate values are generated.

---

### 3. Execution Cycle Datapath
The Execution stage performs:

- ALU computations
- Branch condition evaluation
- Branch target address computation
- Final branch resolution for predictor update

---

### 4. Memory Read/Write Cycle Datapath
Handles memory access for load/store instructions.

---

### 5. Write Back Cycle Datapath
Writes ALU results or loaded data back to the register file.

---

## 🧠 Hazard Unit

The hazard unit monitors:

- Source registers in ID/EX
- Destination registers in EX/MEM and MEM/WB

It generates:

- Forwarding control signals
- Pipeline stall signals if required

---

## 🧪 Simulation & Tools

Simulation Environment:

- **Icarus Verilog**
- **GTKWave for waveform visualization**
- **Visual Studio Code**

Input machine codes are stored in:memfile_bench2.hex


