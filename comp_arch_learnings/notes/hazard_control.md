# Hazard Control

## Data Hazards: Forwarding vs. Stalling

### Instruction Sequence with Dependences

```assembly
sub x2, x1, x3     // x2 written by sub
and x12, x2, x5    // 1st operand (x2) depends on sub
or x13, x6, x2     // 2nd operand (x2) depends on sub
add x14, x2, x2    // both operands depend on sub
sd x15, 100(x2)    // base address (x2) depends on sub
```

### Key Concepts

- **Data hazard**: An instruction depends on the result of a previous instruction that hasn't completed yet.
    
- The value for `x2` is not written until **clock cycle 5**.
    
- `and` and `or` would use an incorrect value of `x2` unless **forwarding** is used.
    

---

### Forwarding (Bypassing)

- **Goal**: Provide the result before it's written back to the register file.
    
- **When**: Required when a value is needed in the EX stage but isn’t yet in the register file.
    

#### Forwarding Conditions

1. **EX hazard** (from EX/MEM):

```text
if (EX/MEM.RegWrite 
    and (EX/MEM.RegisterRd ≠ 0)
    and (EX/MEM.RegisterRd == ID/EX.RegisterRs1)) ForwardA = 10

if (EX/MEM.RegWrite 
    and (EX/MEM.RegisterRd ≠ 0)
    and (EX/MEM.RegisterRd == ID/EX.RegisterRs2)) ForwardB = 10
```

2. **MEM hazard** (from MEM/WB):

```text
if (MEM/WB.RegWrite 
    and (MEM/WB.RegisterRd ≠ 0)
    and not(EX hazard on same register)
    and (MEM/WB.RegisterRd == ID/EX.RegisterRs1)) ForwardA = 01

if (MEM/WB.RegWrite 
    and (MEM/WB.RegisterRd ≠ 0)
    and not(EX hazard on same register)
    and (MEM/WB.RegisterRd == ID/EX.RegisterRs2)) ForwardB = 01
```

- The forwarded value is selected using **ALU multiplexors**.
    
- The **ID/EX pipeline register** is extended to store `rs1` and `rs2`.
    

### Dependence Classification Example

```assembly
sub x2, x1, x3
and x12, x2, x5     // hazard 1a (EX hazard)
or x13, x6, x2      // hazard 2b (MEM hazard)
add x14, x2, x2     // no hazard (register file read occurs in ID after sub writes in WB)
sd x15, 100(x2)     // no hazard (value available in register file)
```

### Stalling: When Forwarding Is Not Enough

- **Load-use hazard**: When a load is followed immediately by an instruction that uses the loaded value.
- Forwarding doesn't help here because the memory read isn’t complete until the end of MEM.


#### Hazard Detection Unit Control

```text
if (ID/EX.MemRead and
   ((ID/EX.RegisterRd == IF/ID.RegisterRs1) or
    (ID/EX.RegisterRd == IF/ID.RegisterRs2)))
   -> stall the pipeline
```

- **Stalling effects**:
    
    - Prevent PC and IF/ID from updating.
        
    - Insert a **nop** in the EX stage (by setting control signals to 0).
        
    - Allow the instruction in MEM/WB to proceed as usual.
        

---

### Implementation Details

- **Register file forwarding**: If read and write occur in the same cycle, return the written value.
    
- **Additional multiplexor** added for selecting between:
    
    - Forwarded operand B
        
    - Immediate value

---

## Control Hazards

Control hazards (also called **branch hazards**) arise from branch instructions that affect the PC. Since the decision to branch isn't known immediately, instructions that follow the branch might be incorrect and must be handled appropriately.

---

### Example: Branch Delay in Basic 5-Stage Pipeline

Assume the pipeline resolves branches in the **MEM** stage:

```assembly
40   sub x10, x4, x8
44   beq x1, x3, 16   # Branch target is PC + 16*2 = 72
48   and x12, x2, x5
52   or x13, x2, x6
56   add x14, x4, x2
60   sub x15, x6, x7
...
72   ld x4, 50(x7)
```

- The **branch decision** is made in **clock cycle 4** (MEM stage).
    
- Until then, the three instructions after `beq` are fetched and may execute.
    
- If the branch is taken, they must be **flushed**.
    

## Resolving Control Hazards

### 1. **Assume Branch Not Taken**

- Predict branches are **not taken** and continue fetching sequentially.
    
- If prediction is wrong, **flush the pipeline** and fetch from the branch target.
    

#### Flushing Instructions

- Set the control signals of IF, ID, and EX stages to **0** to convert them to **nops**.
    
- Flushing is triggered **when branch decision is known** (e.g., MEM stage).
    

### 2. **Move Branch Execution Earlier (to ID Stage)**

- Compute branch **target address** and evaluate **branch condition** in ID stage.
    
- Branch target address is calculated using PC + immediate.
    
- Branch condition (e.g., for `beq`) can be checked via **XOR and OR** logic.
    

#### Benefits

- Reduces taken-branch penalty to **one cycle** (only IF stage instruction is wrong).
    

#### Challenges

- Requires **additional forwarding logic** to supply operands for comparison in ID.
    
- Introduces **stall cycles** if branch depends on a result still in the pipeline:
    
    - **1 stall** for dependent ALU instruction
        
    - **2 stalls** for dependent load instruction
        

### Control Signal: `IF.Flush`

- A new control line `IF.Flush` is added.
    
- Clears the instruction in IF/ID register (makes it a **nop**).
    
### Pipelined Branch Example

With **branch execution moved to ID**, only one bubble is inserted on taken branches:

```assembly
36 sub x10, x4, x8
40 beq x1, x3, 16
44 and x12, x2, x5
48 or x13, x2, x6
52 add x14, x4, x2
72 ld x4, 50(x7)
```

At **clock cycle 3**, `beq` is in ID stage and determines branch taken:

- Instruction at 72 is fetched in **cycle 4**.
    
- Instruction at 44 is flushed (converted to nop).
    

## Dynamic Branch Prediction

### 1. **1-Bit Predictor**

- Keeps track of whether branch was taken last time.
    
- Indexed using low bits of instruction address.
    
- **Prediction accuracy issue**: loops with 9 taken branches and 1 not taken result in 2 mispredictions.
    

#### Accuracy Example

Loop branches taken 9 times, not taken once:

- Mispredicts:
    
    - On **1st iteration** (predicts not taken due to last exit)
        
    - On **10th iteration** (predicts taken, but not taken)
        
- Accuracy: 8 correct, 2 incorrect = **80%**
    

---

### 2. **2-Bit Predictor**

- Uses a 2-bit **saturating counter**.
    
- Four states: Strongly Taken, Weakly Taken, Weakly Not Taken, Strongly Not Taken.
    
- Requires **two mispredictions** to change direction.
    

#### Finite State Machine

```text
[00] Strongly Not Taken → [01] Weakly Not Taken → [11] Weakly Taken → [10] Strongly Taken
```

- Correct predictions reinforce state.
    
- Incorrect predictions move to less confident state.
    

### Branch Prediction Buffer (History Table)

- Small memory indexed by low bits of instruction address.
    
- Stores 1 or 2-bit predictor state.
    
- Accessed during **IF stage**.
    
- **If wrong**:
    
    - Flush incorrect path
        
    - Invert/update predictor bit
        

---

### Branch Target Buffer (BTB)

- Caches **target PC** or **target instruction**.
    
- Speeds up redirection after a taken branch.
    
- Works in combination with predictor to minimize penalty.
    

---

## Advanced Predictors

### 1. **Correlating Predictor**

- Uses **local** behavior of current branch **plus** **global** behavior of recent branches.
    
- Improves prediction accuracy.
    
- Example: Use recent N branch outcomes as extra index bits.
    

### 2. **Tournament Predictor**

- Multiple predictors (e.g., local vs. global).
    
- **Selector** chooses which predictor to trust per branch.
    
- Selector uses a 1- or 2-bit predictor itself, updated by past accuracy.
    

---

## Reducing Conditional Branches

Some ISAs (e.g., ARMv8) use **conditional move** instructions to reduce branches.

Example: `CSEL` in ARMv8

```assembly
CSEL X8, X11, X4, NE
```

- If condition (`NE`) is true, `X8 = X11`
    
- Else, `X8 = X4`
    

This reduces control hazards by **avoiding branches altogether**.

---

## Exceptions

Handling **exceptions and interrupts** is one of the most complex parts of processor control design. These are events that cause a **change in the normal program execution flow**—either from **inside** (e.g., undefined instruction) or **outside** (e.g., I/O).
### Terminology

|Term|Definition|
|---|---|
|**Exception**|Any **unscheduled event** that disrupts normal execution (internal or external)|
|**Interrupt**|A **subset of exceptions**, caused by **external sources**|

RISC-V uses:

|Event|Origin|RISC-V Classification|
|---|---|---|
|System reset|External|Exception|
|I/O device request|External|Interrupt|
|Syscall from user mode|Internal|Exception|
|Execution of undefined instruction|Internal|Exception|
|Hardware malfunction|Either|Either|

## Handling Exceptions in RISC-V

The processor takes these steps when an exception occurs:

1. **Save the address** of the instruction that caused the exception to `SEPC`.
    
2. **Record the cause** in `SCAUSE`.
    
3. **Transfer control** to a predefined OS handler (e.g., at `0x000000001C090000`).
    
4. OS takes action (handle, restart, or terminate).
    
5. **(Optional)** Resume program using the saved PC in `SEPC`.
    
### Exception Communication

#### Method 1: Register-Based (RISC-V)

- `SEPC`: Holds the address of the faulting instruction (64 bits).
    
- `SCAUSE`: Holds a code indicating the cause.
    
    - e.g., `2` = undefined instruction, `12` = hardware fault
        

#### Method 2: Vectored Interrupts

- Each exception cause maps to a **unique address offset** from a vector base.
    
- Example vector base system:
    

|Cause|Offset (binary)|
|---|---|
|Undefined instruction|`0001000000₂`|
|Hardware malfunction|`0110000000₂`|

- OS jumps directly to appropriate handler via computed vector address.
    

---

## Exceptions in a Pipelined Processor

In pipelined implementations, exceptions are treated as a **control hazard**.

### Example Scenario

- An `add` instruction experiences a **hardware malfunction**.
    
- As with branch hazards, **flush** subsequent instructions.
    
- Begin fetching from the **exception handler address** (`0x1C090000`).
    

### Pipeline Flush Mechanism

|Stage|Signal|Effect|
|---|---|---|
|IF|`IF.Flush`|Turns IF instruction into a nop|
|ID|`ID.Flush`|ORed with stall signal, zeros control|
|EX|`EX.Flush`|Zeros EX stage control lines|

### PC Redirection

- PC mux gets an **additional input**: `0x000000001C090000`.
    
- Used when an exception is triggered.
    

### Key Additions to Datapath

1. **`SEPC`** register: stores PC of offending instruction.
    
2. **`SCAUSE`** register: stores cause code.
    
3. **EX.Flush**: prevents faulting instruction from modifying state.
    
### Instruction Restarting

To **re-execute** the faulting instruction:

- Flush it from the pipeline.
    
- Resume execution using `SEPC`.
    

If the faulting instruction **modifies state**, like writing to a register, EX.Flush ensures it does **not** take effect unless the instruction completes normally after exception handling.

---

## Summary

- **Exceptions** are handled via flushing and redirection.
    
- RISC-V records cause (`SCAUSE`) and PC (`SEPC`).
    
- Treated similarly to **control hazards** in the pipeline.
    
- OS uses handler at fixed address or vector table.
    
- Proper design ensures **correct recovery** and **minimal disruption** to the pipeline.
