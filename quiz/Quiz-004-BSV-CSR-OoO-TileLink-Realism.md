## **Quiz 004: BSV, CSR, OoO & TileLink Realism**

---

### 1. **BSV Rule Scheduling**

In Bluespec, consider two rules:

```bsv
rule send;
  ifc.send(data);
endrule

rule receive;
  data <- ifc.receive;
endrule
```

Can both rules fire in the same cycle?

a) Yes  
b) No  
c) Only if using `(* descending_urgency *)`  
d) Only if `receive` is in a different clock domain

<details> <summary>Click here for the answer</summary>

**Answer:** b) No  
**Explanation:**  
In this setup, both rules are trying to perform conflicting operations on the same interface (`ifc`), one trying to send, and the other trying to receive. BSV enforces atomicity and interface semantics, so both can’t fire in the same cycle unless the interface is explicitly designed to support such simultaneous usage, which is rare. Thus, this causes a **rule scheduling conflict**, and only one can proceed per cycle.

</details>

---

### 2. **CSR Trap Behavior**

In RISC-V, if a program triggers an illegal instruction trap, what register holds the address of the faulting instruction?

a) `mstatus`  
b) `mepc`  
c) `mcause`  
d) `mtval`

<details> <summary>Click here for the answer</summary>

**Answer:** b) `mepc`  
**Explanation:**  
`mepc` (Machine Exception Program Counter) holds the address of the instruction that caused the exception or trap. This allows the trap handler to resume or analyze the faulting instruction.

</details>

---

### 3. **TileLink Atomic Requests**

Which TileLink channel supports atomic memory operations (e.g., LR/SC or AMOs)?

a) A  
b) D  
c) C  
d) E

<details> <summary>Click here for the answer</summary>

**Answer:** a) A  
**Explanation:**  
TileLink atomic operations are issued as part of `A` channel requests (like `Acquire`, `PutAtomic`, etc.). The `A` channel is used by the initiator to send read/write/atomic requests.

</details>

---

### 4. **Register Renaming Motivation**

Why do OoO processors rename registers?

a) To reduce the size of the register file  
b) To eliminate WAR and WAW hazards  
c) To reuse physical registers faster  
d) To improve decode speed

<details> <summary>Click here for the answer</summary>

**Answer:** b) To eliminate WAR and WAW hazards  
**Explanation:**  
Register renaming maps architectural registers to a larger set of physical registers, which breaks false dependencies like Write-After-Write (WAW) and Write-After-Read (WAR), allowing more instructions to execute out-of-order without interference.

</details>

---

### 5. **Decode + Hazard Reasoning**

Given this instruction sequence:

```asm
addi x5, x0, 1  
addi x6, x0, 2  
add  x7, x5, x6  
sub  x5, x7, x6
```
Without forwarding, what kind of hazard causes the last instruction to potentially compute wrong?

a) Read-after-write  
b) Write-after-write  
c) Write-after-read  
d) Structural

<details> <summary>Click here for the answer</summary>

**Answer:** a) Read-after-write  
**Explanation:**  
The last instruction (`sub x5, x7, x6`) depends on the result of `add x7, x5, x6`, which in turn depends on previous instructions. Without forwarding, `x7` may not have been written back yet when the `sub` is in EX, causing incorrect operand values. This is a **Read-After-Write (RAW)** hazard.

</details>

---

See you on Day-5!