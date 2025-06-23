
# CRegs in BSV

## What is a CReg?

A `CReg` (Concurrent Register) is a register-like primitive in BSV that enables **multiple rules** to read/write a value concurrently within the **same clock cycle**. It solves the concurrency limitations of regular `mkReg`.

### Why not `mkReg`?

`mkReg` has method ordering constraints:

`_read < _write`

This means a rule that writes to a `Reg` can't have its effect visible until the next clock. If multiple rules try to read/write the same `Reg` in one clock, **a conflict occurs**.

---

## Example: 2-Port Saturating Counter

### Interface

```bsv
interface UpDownSatCounter_Ifc;
  method ActionValue #(Int #(4)) countA (Int #(4) delta);
  method ActionValue #(Int #(4)) countB (Int #(4) delta);
endinterface
```

This counter: Has two ports: `countA` and `countB`, updates internal `Int#(4)` state with `delta` , saturates at +7 and -8 returns the **old** value before the update.

---

## Version 1: Using `mkReg` (Not Truly Concurrent)

### Implementation

```bsv
module mkUpDownSatCounter (UpDownSatCounter_Ifc);
  Reg #(Int #(4)) ctr <- mkReg (0);

  function ActionValue #(Int #(4)) fn_count (Int #(4) delta);
    actionvalue
      Int #(5) new_val = extend (ctr) + extend (delta);
      if (new_val > 7)        ctr <= 7;
      else if (new_val < -8)  ctr <= -8;
      else                    ctr <= truncate (new_val);
      return ctr;  // returns old value
    endactionvalue
  endfunction

  method countA (Int #(4) deltaA) = fn_count (deltaA);
  method countB (Int #(4) deltaB) = fn_count (deltaB);
endmodule
```

### Problem

Both `countA` and `countB` operate on `ctr`. Because they share the same `mkReg`, BSV can't schedule them in the same clock cycle.

> [!WARNING]
> Warning: Rule "r10" was treated as more urgent than "r11". Conflicts: countA vs countB both read/write ctr

![expected_behavior](/images/expected_behavior.png)

---

## Version 2: Using `mkCReg` (True 2-Port Support)

### Implementation

```bsv
module mkUpDownSatCounter (UpDownSatCounter_Ifc);
  CReg#(2, Int #(4)) ctr <- mkCReg(0);  // 2 ports

  function ActionValue #(Int #(4)) fn_count (Integer p, Int #(4) delta);
    actionvalue
      Int #(5) new_val = extend (ctr.ports[p]) + extend (delta);
      if (new_val > 7)        ctr.ports[p] <= 7;
      else if (new_val < -8)  ctr.ports[p] <= -8;
      else                    ctr.ports[p] <= truncate (new_val);
      return ctr.ports[p];
    endactionvalue
  endfunction

  method countA (Int #(4) delta) = fn_count (0, delta); // uses port 0
  method countB (Int #(4) delta) = fn_count (1, delta); // uses port 1
endmodule
```

### Behavior

This version allows `countA < countB` to both run in the **same clock**, thanks to:

`ports[0]._read <= ports[0]._write < ports[1]._read <= ports[1]._write`

This defines a logical rule ordering for the compiler to use.

![v2](/images/v2.png)

---

## Summary of CReg Method Ordering

If `n = 3`, the CReg ports allow:

`ports[0]._read <= ports[0]._write < ports[1]._read <= ports[1]._write < ports[2]._read <= ports[2]._write`

This lets you pipeline operations through sequential ports, enabling multiple reads and writes per clock cycle with **well-defined semantics**.

![creg_implementation](/images/creg_implementation.png)


