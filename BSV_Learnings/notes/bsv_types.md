# Types in Bluespec SystemVerilog 

## Purpose of Types

- **Abstraction**: Types let us reason in terms of structured data (e.g., IP packets, employee records) instead of raw bits.
- **Safety**: Strong typing avoids bugs like subtracting two IP addresses or squaring a symbolic state.
- **Modern view**: A type is a *set of abstract values with operations*, not just a bit layout.
- In BSV, this abstract view is **strictly enforced**, even for registers.

> “If it gets through the type checker, it just works.” — BSV/Haskell programmers

---

##  Types in BSV

- Scalar types (`Bit`, `Int`, `UInt`, etc.)
- SystemVerilog-style `typedef`, `enum`, `struct`, `union`, etc.
- Polymorphism via type parameters
- First-class types: modules, interfaces, rules, functions
- Typeclasses and instances (like Haskell or advanced C++)
- Strict, safe: **no silent truncation or extension**

---

##  Syntax of Types: Type Expressions

### Form

`Type ::= TypeConstructor #(Type1, ..., TypeN)`
`| TypeConstructor // when N = 0 `
### Examples

| Type                     | Meaning                                      |
|--------------------------|----------------------------------------------|
| `Integer`                | Unbounded signed (for static elaboration)    |
| `Int#(18)`               | 18-bit signed int                            |
| `UInt#(42)`              | 42-bit unsigned int                          |
| `Bit#(23)`               | 23-bit raw bit vector                        |
| `Bool`                   | Boolean (`True` / `False`)                   |
| `Reg#(UInt#(42))`        | Register of 42-bit unsigned                  |
| `Mem#(A, D)`             | Memory with addr type `A`, data type `D`     |
| `Server#(Rq, Rsp)`       | Server with request/response types           |

---

## `typedef`, `enum`, and `struct`

### Enum

```bsv
typedef enum { Noop, Add, Bz, Ld, St } Opcode deriving (Bits, Eq);
```

>deriving (Bits): auto bit representation, deriving (Eq): auto equality comparison



### Structs

```bsv
typedef struct {
  Opcode op;
  RegName dest;
  Bit#(32) v1;
  Bit#(32) v2;
} DecodedInstr deriving (Bits);
```

> New, strongly-typed values, members can be directly assigned or initialized with struct expressions.


```bsv
rule fetch (buf.notStall(instr));
  let di = DecodedInstr {
    op: instr.op,
    dest: instr.dest,
    v1: rf.sel1(instr.src1),
    v2: rf.sel2(instr.src2)
  };
  buf.enq(di);
  pc <= pc + 1;
endrule
```

---
## Vectors

- Import required: `import Vector :: *;`
- Used for repeated/parallel data structures

`typedef Vector#(10, Vector#(5, Int#(16))) Matrix;`

### Indexing

```bsv
Int#(5) new_val = extend(ctr.ports[p]) + extend(delta);
if (new_val > 7) ctr.ports[p] <= 7;
```

---
### Numeric Types
- Numeric types are a restricted static type-level language
- Needed for sizes, vector lengths, etc.

### Examples

| Expression               | Meaning                            |
| ------------------------ | ---------------------------------- |
| `Int#(18)`               | 18-bit signed                      |
| `Vector#(16, UInt#(42))` | 16-entry vector of 42-bit unsigned |
| `TAdd#(18,16)`           | Type-level 34                      |
| `TMul#(2,32)`            | Type-level 64                      |
| `TLog#(19)`              | Type-level ⌈log₂(19)⌉              |

### Notes

- **Not** interchangeable with runtime numeric expressions.
- Use `valueOf(numeric_type)` to convert to runtime value.


```bsv
function Integer valueOf(numeric_type);
```
---

## Polymorphic Types
Type parameters can be type variables:

```bsv

Int#(n)               // n-bit int
Vector#(m, t)         // m-element vector of type t
```

> Enables generic, reusable components

`Maybe` Type: Tagged Union

```bsv
typedef union tagged {
  void Invalid;
  t Valid;
} Maybe#(type t) deriving (Eq, Bits);
```

Use

```bsv
Maybe#(UInt#(8)) maybeVal = tagged Valid 42;

if (maybeVal matches tagged Valid .x)
  $display("Valid value: %0d", x);
else
  $display("Invalid value");
```
> Safe alternative to C-style unions, no accidental use of invalid data. 

---

## Tuple Types
- `Tuple2#(t1, t2)` represents a pair
- Convenient functions for deconstruction:

```bsv
Tuple2#(Bit#(8), Bit#(8)) pair = tuple2(10, 20);

match { .x, .y } = pair;
$display("%0d %0d", x, y);
```

---
## Exporting Abstract Types

In Bar.bsv


```bsv
package Bar;
typedef struct {
  Bit#(16) addr;
  Bit#(32) data;
} Request;
export Request, mkBar;

module mkBar(...);
  method Request m1(...);
  method Action m2(Request r);
endmodule
endpackage
```

In Foo.bsv

`import Bar :: *;`

> Can declare/register `Request` type, cannot access field names (`addr`, `data`), `request` is opaque in `Foo`. This allows for encapsulation and abstract interfaces. 