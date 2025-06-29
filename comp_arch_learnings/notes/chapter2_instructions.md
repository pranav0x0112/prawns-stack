# Instructions - The Language of the Computer

**Instruction set** - The vocabulary of commands understood by a given architecture. Some popular ones are RISC-V, MIPS, x86.

**Stored-program concept** - The idea that instructions and data of many types can be stored in memory as numbers and thus be easy to change, leading to the stored-program computer. But what does this mean? 

```assembly
addi x5, x0, 10 # x5 = x10 
addi x6, x0, 20 # x6 = 20
add x7, x5, x6 # x7 = x5 + x6 = 30
```

After assembling, these become machine code — just numbers in memory:

|Address|Machine Code (Hex)|Instruction|
|---|---|---|
|0x0000|0x00A00293|`addi x5, x0, 10`|
|0x0004|0x01400313|`addi x6, x0, 20`|
|0x0008|0x006283B3|`add x7, x5, x6`|

These binary values are **just 32-bit numbers** — memory treats them the same as any other data.

### Now the fun part is:

Suppose you store the number `10` later in memory like this:

|Address|Data (binary or hex)|Meaning|
|---|---|---|
|0x0100|`0x0000000A`|Integer value `10`|

→ From memory’s perspective, there's **no difference** — both instructions and data are just 32-bit numbers stored at addresses.  
The CPU only knows which is **code** and which is **data** based on **how it accesses** them:

- **PC (program counter)** is used to **fetch instructions**
- **Load/store instructions** are used to fetch **data**

### And this is why:

- You can write **self-modifying code** (change your own instructions in memory — not common today but possible)
- Attackers can inject “data” that turns into executable instructions (hello, buffer overflows and shellcode )
- Systems need to **mark memory regions** as code vs data (`.text`, `.data`, executable permissions, etc.)

>[!IMPORTANT]
> Memory holds everything as numbers. Whether a number is **data** or an **instruction** depends entirely on **how the CPU uses it** — that’s the beauty (and danger) of the stored-program concept.

![risc-v_operands]()
