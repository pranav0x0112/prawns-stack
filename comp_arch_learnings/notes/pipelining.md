# Pipelining in RISC-V

## What is Pipelining?

Pipelining is a technique used in modern processor design to improve instruction throughput. It allows multiple instructions to be executed simultaneously by dividing instruction execution into separate stages. Each stage completes part of an instruction in a single clock cycle.

This approach increases overall efficiency, enabling one instruction to be completed per cycle in the ideal case, thereby maximizing instruction throughput.

### Classic 5-Stage Pipeline

1. **IF (Instruction Fetch)**
2. **ID (Instruction Decode and Register Fetch)**
3. **EX (Execute)**
4. **MEM (Memory Access)**
5. **WB (Write Back)**

Each stage works on a different instruction at the same time. For example, while instruction 1 is in EX, instruction 2 can be in ID and instruction 3 in IF.

## Advantages of Pipelining

* Increased instruction throughput
* Efficient use of processor components
* Enables high-performance designs in CPUs and embedded systems

## Instruction Flow Example

Assume the following instructions:

```asm
add x1, x2, x3
sub x4, x1, x5
lw x6, 0(x7)
```

Each instruction will occupy a different stage of the pipeline in each clock cycle, enabling overlapping execution.

### Case 1: **No Forwarding** (Classic 5-stage pipeline, with stalls)

We’ll insert **two stall cycles** after the `add`, since `x1` will be written back in cycle 5, but `sub` needs it in its **EX stage**, which would be in cycle 3.

|**Cycle**|**IF**|**ID**|**EX**|**MEM**|**WB**|
|---|---|---|---|---|---|
|1|`add x1, x2, x3`|||||
|2|`stall`|`add x1, x2, x3`||||
|3|`stall`||`add x1, x2, x3`|||
|4|`sub x4, x1, x5`|||`add x1, x2, x3`||
|5|`lw x6, 0(x7)`|`sub x4, x1, x5`|||`add x1, x2, x3`|
|6||`lw x6, 0(x7)`|`sub x4, x1, x5`|||
|7|||`lw x6, 0(x7)`|`sub x4, x1, x5`||
|8||||`lw x6, 0(x7)`|`sub x4, x1, x5`|
|9|||||`lw x6, 0(x7)`|

---

### Case 2: **With Forwarding** (data forwarded from MEM/WB to EX)

With forwarding, we can reduce this to a **single stall**, because the result of `add` can be forwarded to the `EX` stage of `sub`.

|**Cycle**|**IF**|**ID**|**EX**|**MEM**|**WB**|
|---|---|---|---|---|---|
|1|`add x1, x2, x3`|||||
|2|`stall`|`add x1, x2, x3`||||
|3|`sub x4, x1, x5`||`add x1, x2, x3`|||
|4|`lw x6, 0(x7)`|`sub x4, x1, x5`||`add x1, x2, x3`||
|5||`lw x6, 0(x7)`|`sub x4, x1, x5`||`add x1, x2, x3`|
|6|||`lw x6, 0(x7)`|`sub x4, x1, x5`||
|7||||`lw x6, 0(x7)`|`sub x4, x1, x5`|
|8|||||`lw x6, 0(x7)`|

---

# Pipeline Hazards

Hazards are conditions that prevent the next instruction from executing during its designated clock cycle. There are three types:

## 1. Structural Hazards

Occur when two instructions need the same hardware resource simultaneously.

**Example:** If both instruction fetch and data memory access require the same memory hardware in the same cycle, a structural hazard occurs.

**Solution:** Use separate instruction and data memories (Harvard architecture), or pipeline access to shared resources.

---

## 2. Data Hazards

Occur when an instruction depends on the result of a previous instruction that is still in the pipeline.

### Example:

```asm
add x1, x2, x3
sub x4, x1, x5
```

Here, `sub` depends on the result of `add`, but `add` writes back in WB, which is two cycles after `sub` reads the register in ID.

### Solution: Forwarding (Bypassing)

Instead of waiting for `x1` to be written to the register file, the result from the EX stage of `add` can be forwarded directly to the EX stage of `sub`.

**Limitations:** Forwarding cannot help with load-use hazards, where the result of a `lw` instruction is needed immediately by the next instruction.

### Example of Load-Use Hazard:

```asm
lw x1, 0(x2)
add x3, x1, x4
```

Even with forwarding, `x1` is available only after MEM, too late for the next instruction.

### Solution: Pipeline Stall (Bubble)

Introduce a no-op (stall) between dependent instructions so the data is available in time.

### Avoiding Stalls with Code Reordering

Rewriting code to avoid data hazards.

```asm
// Original
ld x1, 0(x31)
ld x2, 8(x31)
add x3, x1, x2
sd x3, 24(x31)
ld x4, 16(x31)
add x5, x1, x4
sd x5, 32(x31)

// Reordered
ld x1, 0(x31)
ld x2, 8(x31)
ld x4, 16(x31)
add x3, x1, x2
sd x3, 24(x31)
add x5, x1, x4
sd x5, 32(x31)
```

Reordering the `ld x4` instruction prevents a stall by giving enough time for the `ld x1` result to be available.

---

## 3. Control Hazards

Also known as branch hazards, these occur when the processor does not know which instruction to fetch next due to a conditional branch.

### Example:

```asm
beq x1, x2, LABEL
```

Until the branch is resolved in the ID or EX stage, the next instruction to fetch is unknown.

### Solution 1: Stall on Branch

Wait until the branch is resolved before fetching the next instruction. Simple but inefficient.

### Solution 2: Branch Prediction (covered later)

Predict the branch direction and speculatively fetch the next instruction. If the prediction is wrong, flush the pipeline and correct it.

### Hardware Requirements

To minimize control hazards, some designs allow calculating the branch target and condition early (in ID stage) and updating the PC accordingly.

---

## Summary of Hazards and Solutions

| Hazard Type | Cause                                  | Solution                          |
| ----------- | -------------------------------------- | --------------------------------- |
| Structural  | Resource conflict                      | Duplicate resources or scheduling |
| Data        | Instruction depends on previous result | Forwarding, stalls, reordering    |
| Control     | Branch outcome not yet known           | Stalls, branch prediction         |


