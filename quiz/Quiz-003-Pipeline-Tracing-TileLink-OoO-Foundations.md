## Quiz 003: Pipeline Tracing, TileLink, and OoO Foundations

### 1. **Pipeline Trace**

You have a 5-stage pipeline (IF, ID, EX, MEM, WB).  
Given this code:

```asm
addi x1, x0, 5  
addi x2, x0, 3  
add  x3, x1, x2
```

Assume no forwarding and no stalls injected by hardware.  
At which cycle does `x3` get written back?  
(_Start counting from cycle 1, where first instr is in IF._)

<details> <summary>Click here for the answer</summary>

**Answer:** **Cycle 7**  
**Explanation:**  
Without forwarding or stalls, all instructions proceed through the pipeline normally:

- `addi x1` writes back in **cycle 5**
    
- `addi x2` writes back in **cycle 6**
    
- `add x3` reads x1 and x2 in its EX stage (**cycle 5**) — but at this point:
    
    - x1 is only _just_ being written back (end of cycle 5)
        
    - x2 hasn’t been written back yet (it’s in MEM in cycle 5)
        

So `add` uses old values — but since no stall or hazard resolution is implemented, it proceeds anyway.  
It reaches **WB in cycle 7**, so x3 is written back then — regardless of correctness.

</details>

---
### 2. **TileLink Master Behavior**

A TileLink-lite master sends a `PutFullData` (write) request. What must it do before sending another request to a different address?

a) Wait for a response on the D channel  
b) Send a Probe  
c) Clear a grant bit  
d) Nothing, TileLink is fully async

<details> <summary>Click here for the answer</summary>

**Answer:** a) Wait for a response on the D channel  
**Explanation:**  
TileLink requires a master to wait for the corresponding response (on the D channel) before issuing a new transaction to a different address. This maintains ordering and prevents conflicts.

</details>

---

### 3. **RISC-V Encoding**

What field(s) determine the destination register in an `ADD` instruction?

a) rs1  
b) rs2  
c) rd  
d) funct3

<details> <summary>Click here for the answer</summary>

**Answer:** c) rd  
**Explanation:**  
In R-type instructions like `ADD`, the `rd` field (bits [11:7]) specifies the destination register where the result will be written.

</details>

---

### 4. **OoO Core: What is a ROB?**

What is the main purpose of the Reorder Buffer (ROB) in an OoO CPU?

a) Track pipeline stalls  
b) Allocate registers  
c) Commit instructions in program order  
d) Forward data to ALU early

<details> <summary>Click here for the answer</summary>

**Answer:** c) Commit instructions in program order  
**Explanation:**  
The ROB holds instructions that have executed out-of-order and ensures they are committed in-order to preserve architectural state and exception correctness.

</details>

---

### 5. **C to Assembly Reasoning**

Given this C code:

```c
int a = 4, b = 6;
int c = a + b;
```

Which RISC-V instruction sequence best matches this?

a) 
```asm
li x1, 4  
li x2, 6  
add x3, x1, x2
```

b)
```asm
addi x1, x0, 4  
addi x2, x0, 6  
add x3, x2, x1
```

c)

```asm
li x3, 10
```

d) All of the above

<details> <summary>Click here for the answer</summary>

**Answer:** b)  
**Explanation:**  
While `li` is a valid pseudo-instruction, it’s not a core RISC-V instruction. Option **b** uses only base RV32I instructions (`addi` and `add`), which is what compilers often emit for constants.  
Option c is incorrect because it performs constant folding (i.e., compile-time addition), but in C the addition is done at runtime. So **b** best reflects the semantics of the original C code.

</details>

---

See you on Day-4!