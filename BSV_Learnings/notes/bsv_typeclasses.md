## Typeclasses in Bluespec SystemVerilog

## Overview

Bluespec SystemVerilog (BSV) supports two powerful type parameterization mechanisms:

- **Polymorphism**: General code that can operate on any type.
    
- **Overloading (via Typeclasses)**: Multiple functions with the same name operating on different types.
    

Overloading in BSV is modeled after Haskell’s typeclass system, allowing clean abstraction, reuse, and compile-time safety.

---

## Overloading and Typeclasses

### Key Concepts:

- **Typeclasses**: Define a group of related overloaded identifiers.
    
- **Instances**: Provide definitions for the typeclass operations on specific types.
    
- **Provisos**: Constraints stating a type must be an instance of a specific typeclass.
    
- **Deriving**: Automatic generation of instances for common typeclasses like `Bits`, `Eq`, `FShow`.
    

### Motivation:

Overloading enables abstraction over operations like:

- `+` for various number types
    
- Pretty-printing
    
- Equality checking
    
- Bit-packing for hardware representation
    

---

## Common Typeclasses

|Typeclass|Purpose|Example Ops|
|---|---|---|
|`Bits`|Conversion to/from `Bit#(n)`|`pack`, `unpack`|
|`Eq`|Equality operations|`==`, `!=`|
|`Arith`|Arithmetic|`+`, `-`, `*`, `/`|
|`Ord`|Comparisons|`<`, `<=`, `>`, `>=`|
|`FShow`|Pretty-printing|`fshow`|
|`Literal`|Integer literal conversion|`fromInteger`|
|`Bitwise`|Bitwise ops|`&`, `|`,` ^`,` ~`|
|`BitExtend`|Bit extensions/truncation|`extend`, `truncate`|

---

## Defining Instances

```
instance Bits#(Opcode, 4);
  function Bit#(4) pack(Opcode op);
    case(op)
      Noop: return 4'b0010;
      Add : return 4'b0100;
      ...
    endcase
  endfunction

  function Opcode unpack(Bit#(4) b);
    case(b)
      4'b0010: return Noop;
      4'b0100: return Add;
      ...
    endcase
  endfunction
endinstance
```

Or use `deriving`:

```
typedef enum { Noop, Add, Bz, Ld, St } Opcode deriving (Bits, Eq, FShow);
```

---

## Provisos

Used to constrain type parameters to be part of certain typeclasses.

```
function Vector#(n, t) sort(Vector#(n, t) v)
  provisos (Ord#(t));
  ...
endfunction
```

Another example in module headers:

```
module mkFoo#(...) (InterfaceType#(t))
  provisos (Bits#(t, tsize), Eq#(t), Arith#(t));
```

---

## Literal Typeclass

Allows conversion from `Integer` to user-defined or built-in types.

```
typeclass Literal#(type t);
  function t fromInteger(Integer i);
endtypeclass

rg_x <= 2012; // interpreted as fromInteger(2012)
```

---

## FShow and Pretty Printing

```
typeclass FShow#(type t);
  function Fmt fshow(t x);
endtypeclass

instance FShow#(Opcode);
  function Fmt fshow(Opcode op);
    case(op)
      Noop: return $format("Noop");
      Add:  return $format("Add");
      ...
    endcase
  endfunction
endinstance
```

Use with:

```
$display("Opcode: ", fshow(rg_instr.op));
```

Or use:

```
typedef struct { ... } Instr deriving (Bits, FShow);
```

---

## Numeric Typeclasses

Used for relationships between numeric type parameters (non-extensible):

```
module mkMyFifo (MyFifo#(n, t))
  provisos (Log#(n, m));
  ...
  Reg#(Bit#(m)) rg_head <- mkReg(0);
  ...
endmodule
```

Examples:

- `Add#(a, b, c)` → `a + b = c`
    
- `Log#(n, m)` → `m = log2(n)`
    

---

## Summary

BSV’s typeclass system:

- Enables rich polymorphism and abstraction
- Supports strongly-typed hardware modeling
- Promotes reuse and separation of logical types from representation
- Brings modern language features (from Haskell) into hardware design
 
Common workflows:
- Use `deriving (Bits, Eq, FShow)` when possible
- Add `provisos` when working with polymorphic modules/functions
- Define custom `instance` blocks for full control over behavior