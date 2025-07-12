## **Quiz 001: SoC & CPU Core Concepts**

Each is short answer or multiple choice. Don't overthink. Trust your brain.

---

### 1. **Pipeline Hazards**

What kind of hazard occurs when a later instruction **depends on the result** of an earlier instruction still in the pipeline?

a) Structural  
b) Control  
c) Data  
d) TileLink

<details>
<summary> Click here for the answer </summary>

**Answer:** c) Data  
**Explanation:** A data hazard occurs when an instruction needs a value that hasn't been computed yet by a previous instruction.

</details>

---

### 2. **RISC-V Control Flow**

Suppose a RISC-V program executes:

```asm
addi x1, x0, 5  
beq x1, x0, label  
addi x2, x0, 9
label:
addi x3, x0, 4
```

What value does `x2` hold after execution?

<details> <summary>Click here for the answer</summary>

**Answer:** 9  
**Explanation:** `beq x1, x0, label` is false since x1 = 5 and x0 = 0, so the branch is not taken. The program executes `addi x2, x0, 9`, so x2 = 9.

</details>

---

### 3. **TileLink**

What’s the purpose of the **'D' channel** in TileLink?

a) Send address requests  
b) Send grant signals  
c) Return responses (data or ack)  
d) Handle errors

<details> <summary>Click here for the answer</summary>

**Answer:** c) Return responses (data or ack)  
**Explanation:** The D channel is used by the manager to send responses back to the initiator, such as read data or acknowledgments.

</details>

---

### 4. **MPU vs MMU**

In a microcontroller SoC with an **MPU**, what is something it **cannot do** that an MMU can?

<details> <summary>Click here for the answer</summary>

**Answer:** Virtual-to-physical address translation  
**Explanation:** An MPU only enforces access permissions on physical memory regions. It doesn't support virtual memory or translation like an MMU does.

</details>

---

### 5. **Memory Map**

You're designing an SoC with ROM at `0x00000000` (4 KB) and RAM at `0x00001000` (8 KB).  
If your program counter starts at `0x00000000`, where should you put the boot code?

<details> <summary>Click here for the answer</summary>

**Answer:** Put the boot code in ROM at `0x00000000`  
**Explanation:** Since the PC starts at `0x00000000`, the boot code must be placed in ROM so that it’s available at reset.

</details>

---

See you on [Day-2](./Quiz-002-Pipeline-Control-and-Memory-Semantics.md)!