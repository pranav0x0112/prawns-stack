## **Quiz 002: Pipeline Control & Memory Semantics**

---

### 1. **Stalling Logic**

In a 5-stage RISC-V pipeline (IF–ID–EX–MEM–WB), a `lw` is followed by a `sub` that depends on its result:

```asm
lw  x5, 0(x1)  
sub x6, x5, x2
```
What must happen in the pipeline to ensure correct execution?

a) Forward the data  
b) Stall the pipeline  
c) Flush the pipeline  
d) Execute out-of-order

<details> <summary>Click here for the answer</summary>

**Answer:** b) Stall the pipeline  
**Explanation:** A `lw` has a load-use hazard since the data becomes available only after MEM. The following `sub` needs the result in EX, so you must stall one cycle to avoid incorrect data.

</details>

---
### 2. **Memory Write Timing**

In a BSV-based SoC using a synchronous RAM (`mkSimpleRAM`), when you write to RAM on cycle N, **on which cycle is the data visible if you read the same address?**

a) Cycle N  
b) Cycle N + 1  
c) Depends on latency  
d) Immediately due to bypassing

<details> <summary>Click here for the answer</summary>

**Answer:** b) Cycle N + 1  
**Explanation:** Synchronous RAMs in BSV like `mkSimpleRAM` write the data at the rising edge and the new value becomes visible on the next cycle. So you’ll see it in cycle N + 1.

</details>

---

### 3. **Branch Misprediction**

In a simple 5-stage pipeline with no branch prediction, a conditional branch is taken.  
How many instructions after the branch are incorrectly fetched?

a) 0  
b) 1  
c) 2  
d) 3

(_Assume the branch decision is made in EX stage_)

<details> <summary>Click here for the answer</summary>

**Answer:** c) 2  
**Explanation:** Since the branch decision is known in EX, two instructions (in IF and ID stages) have already been fetched assuming the branch wasn’t taken. These must be flushed.

</details>

---

### 4. **RISC-V Instruction Encoding**

What is the **opcode field** (bits [6:0]) for an `SW` (store word) instruction?

a) `0100011`  
b) `0000011`  
c) `0010011`  
d) `1100011`

<details> <summary>Click here for the answer</summary>

**Answer:** a) `0100011`  
**Explanation:** `SW` is a store instruction and uses the opcode `0100011`. Loads like `LW` use `0000011`, and branches use `1100011`.

</details>

---

### 5. **TileLink Behavior**

If a TileLink slave device returns `TL_D_INVALID` as a response on the D channel, what does that typically indicate?

a) Successful operation  
b) NACK or not a valid response  
c) Memory-mapped I/O  
d) Start of a burst transfer

<details> <summary>Click here for the answer</summary>

**Answer:** b) NACK or not a valid response  
**Explanation:** `TL_D_INVALID` is used when the manager (slave) returns a non-valid response—often a NACK (Negative Acknowledge) or placeholder when no real response is generated.

</details>

---
See you on [Day-3](./Quiz-003-Pipeline-Tracing-TileLink-OoO-Foundations.md)!