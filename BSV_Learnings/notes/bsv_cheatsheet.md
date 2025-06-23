# Bluespec SystemVerilog (BSV) Cheatsheet for July Projects

> Covers: `bsv_basics`, `bsv_intro`, `bsv_basic_syntax`, `bsv_rule_semantics`, `bsv_fsm`, `bsv_cregs`, `bsv_types`, `bsv_typeclasses`, `bsv_tlm`

---

## 1. BSV Basics & Intro

- Hardware Description Language with static elaboration and rule-based execution
    
- Purely clocked, synchronous, reactive model
    
- Modules, Interfaces, Rules, and Actions are first-class citizens
    
- Compilation = elaboration + type-checking + scheduling + Verilog generation
    

```bsv
module mkExample(Empty);
  Reg#(UInt#(8)) counter <- mkReg(0);
  rule countUp;
    counter <= counter + 1;
  endrule
endmodule
```

---

## 2. BSV Basic Syntax

### Modules

```bsv
module mkModName(ModuleType);
  ... // definitions
endmodule
```

### Interfaces

```bsv
interface Ifc;
  method Action m1();
  method Bool m2(Bit#(8) x);
endinterface
```

### Instantiating modules

```bsv
Ifc x <- mkModule;
```

### Rules

```bsv
rule name if (cond);
  ...
endrule
```

### Methods and Actions

```bsv
method Action incr();
  counter <= counter + 1;
endmethod
```

---

## 3. Rule Semantics

- Rules execute atomically
    
- Multiple rules can fire concurrently if there's no conflict
    
- Scheduling is conservative to avoid hazards
    
- Rule conflict resolution is compile-time only, no dynamic checks
    
- `(* descending_urgency = "r1, r2" *)` sets priority manually
    

---

## 4. FSMs in BSV

- Use an enumerated type for state
    
- Use a register to store the current state
    
- Use rules to implement transitions
    

```bsv
typedef enum {S0, S1, S2} State deriving (Bits, Eq);
Reg#(State) state <- mkReg(S0);

rule transition;
  case (state)
    S0: state <= S1;
    S1: state <= S2;
    S2: state <= S0;
  endcase
endrule
```

---

## 5. CRegs (Concurrent Registers)

- Defined using `RegFile` or `Vector`
    
- Allow concurrent reads/writes to multiple registers
    

```bsv
Vector#(4, Reg#(Bit#(8))) regs <- replicateM(mkReg(0));
```

Access using standard array notation:

```bsv
regs[0] <= regs[1] + 1;
```

---

## 6. Types in BSV

### Basic Types

|Type|Description|
|---|---|
|`Bool`|Boolean (`True`, `False`)|
|`Bit#(n)`|n-bit bitvector|
|`Int#(n)`|n-bit signed integer|
|`UInt#(n)`|n-bit unsigned integer|
|`Integer`|Unbounded integer (elaboration only)|

### Type Constructors

|Constructor|Meaning|
|---|---|
|`Reg#(t)`|Register storing type `t`|
|`Vector#(n, t)`|Vector of n elements of type `t`|
|`Tuple2#(t1, t2)`|2-tuple with types `t1`, `t2`|
|`Maybe#(t)`|Tagged union: `Valid t` or `Invalid`|
|`Mem#(a,d)`|Memory with address type `a`, data type `d`|

### Enums, Structs, Typedefs

```bsv
typedef enum {A, B, C} MyEnum deriving (Bits, Eq);
typedef struct {
  Bit#(32) val;
  Bool valid;
} MyStruct deriving (Bits);
typedef Bit#(32) Word;
```

### Vectors

```bsv
Vector#(8, Bit#(16)) v;
v[0] <= 42;
```

---

## 7. Typeclasses and Overloading

### Typeclasses

- Collection of related overloaded operations
    

```bsv
typeclass Bits#(type t, numeric type n);
  function Bit#(n) pack(t x);
  function t unpack(Bit#(n) b);
endtypeclass
```

### Instances

```bsv
instance Bits#(Opcode, 3);
  function Bit#(3) pack(Opcode op);
    ...
  endfunction
  function Opcode unpack(Bit#(3) b);
    ...
  endfunction
endinstance
```

### Deriving shortcut

```bsv
typedef enum {Noop, Add} Opcode deriving (Bits, Eq);
```

### Provisos

Used to restrict polymorphic types:

```bsv
function Vector#(n, t) sort(Vector#(n, t) v)
  provisos (Ord#(t));
```

### Built-in Typeclasses

|Typeclass|Provides|
|---|---|
|`Bits`|`pack`, `unpack`|
|`Eq`|`==`, `!=`|
|`Arith`|`+`, `-`, `*`, `/`|
|`Ord`|`<`, `<=`, `>`, `>=`, `min`, `max`|
|`Bounded`|`minBound`, `maxBound`|
|`Bitwise`|`&`, `|
|`BitExtend`|`extend`, `truncate`, ...|
|`FShow`|Pretty printing via `fshow`|
|`Literal`|Conversion from `Integer`|

---

## 8. TLM (Transaction-Level Modeling)

- Interfaces define transactional semantics
    
- Methods in TLM modules often follow req/resp pattern
    
- E.g., Servers:
    

```bsv
interface Server#(type req_t, type resp_t);
  method Action request(req_t req);
  method resp_t response();
endinterface
```

---

## Final Notes

- Deriving `(Bits, Eq)` is mandatory for all types stored in state
    
- Typeclasses allow expressive, safe, and scalable reuse
    
- Provisos make polymorphism safe and explicit
    
- Numeric typeclasses (e.g., `Add#(a,b,c)`) used for bitwidth correctness
    
- Prefer structs/enums over raw `Bit#(n)` for clarity and type safety