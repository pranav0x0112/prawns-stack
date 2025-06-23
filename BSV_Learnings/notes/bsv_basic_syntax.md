# Basic Syntax and Identifiers in BSV

- BSV inherits most basic syntax elements from Verilog/SystemVerilog:
  - Identifiers, comments, whitespace, strings, integer constants, infix operators, etc.
- Follows **standard static scoping rules** for identifier visibility and shadowing.
- **Identifiers are case-sensitive**.

### Naming Conventions

- **Types and constants** begin with an uppercase letter: `Int`, `UInt`, `Bool`, `True`, `False`, etc.
- **Variables and type variables** begin with a lowercase letter: `x`, `y`, `type1`, `mkMult`, etc.

### Legacy Exceptions

- `int` and `bit` are accepted for compatibility with Verilog.
- Recommended BSV equivalents:
  - `Int#(32)` instead of `int`
  - `Bit#(1)` instead of `bit`

### Module Naming

- Modules are typically named with an `mk` prefix (e.g., `mkTestbench`, `mkMult`)
  - `mk` stands for “make” — reflects that modules are **generators**.
  - Instantiating a module gives a fresh instance, like in Verilog.
- This is a **stylistic convention**, not enforced by the language.

---

## Syntax of Types: Type Expressions

BSV uses SystemVerilog-style notation for **parameterized types**.

### General Form

> Type ::= TypeConstructor #(Type1, ..., TypeN) \
> | TypeConstructor // if N = 0, #() can be omitted

- A **type expression** is a type constructor applied to zero or more other types.
- When applied to **zero** types, the `#()` can be omitted.

### Examples of Common Types

| Type                      | Meaning / Notes                                                                 |
|---------------------------|----------------------------------------------------------------------------------|
| `Integer`                 | Unbounded signed integers (used only during static elaboration)                 |
| `Int#(18)`                | 18-bit signed integer                                                           |
| `int`                     | Synonym for `Int#(32)` (legacy)                                                 |
| `UInt#(42)`               | 42-bit unsigned integer                                                         |
| `Bit#(23)`                | 23-bit wide bit vector                                                          |
| `bit[15:0]`               | Synonym for `Bit#(16)` (legacy Verilog-style)                                   |
| `Bool`                    | Boolean type with constants `True` and `False`                                  |
| `Reg#(UInt#(42))`         | Interface of a register that holds a 42-bit unsigned integer                    |
| `Mem#(A, D)`              | Interface of a memory with address type `A` and data type `D`                   |
| `Server#(Rq, Rsp)`        | Interface for a server module with request type `Rq` and response type `Rsp`   |

---

## Overall Structure of a BSV Program

- A BSV program consists of one or more **packages** (files with `.bsv` extension).
- A package can **import** other packages (including BSV standard libraries) to use their definitions.
- There is **no special `main` module** like in C; you specify the top-level module to the compiler (`bsc`) manually.
- The top-level module used for simulation typically implements the **`Empty`** interface.

![syntactic_structure](/images/syntactic_structure.png)

---

## What’s in a BSV Package

- `package Foo; ... endpackage: Foo` — Declares the package (name must match filename `Foo.bsv`)
- `import Baz :: *;` — Makes all top-level definitions from package `Baz` visible
- `export a, b;` — Makes specific identifiers (`a`, `b`) available to other packages
- `typedef struct {...} S;` — Defines a new composite type `S`
- `interface Foo_IFC; ... endinterface` — Declares an interface (API contract for modules)
- `UInt#(16) a = 23;` — Constant or value definition
- `function int f(int x); ... endfunction` — Defines a function
- `module mkFoo(...); ... endmodule` — Defines a synthesizable hardware module

![package](/images/package.png)

![name_space](/images/name_space_control.png)

--- 

## Separate Compilation in BSV

The `bsc` compiler processes each `.bsv` file **independently**:
- Performs **parsing**, **typechecking**, **name resolution**, etc., per file
- Generates Verilog or Bluesim code **only** for modules marked with `(* synthesize *)`  
  (or when explicitly named using `-g` on the command line)

### Using `(* synthesize *)`

You should mark **every module you might simulate or synthesize** with `(* synthesize *)`. Why?

- **Enables incremental compilation** — unchanged modules aren’t recompiled
- **Speeds up builds** for large projects
- **Preserves internal structure** in the output (useful for debugging, waveform analysis)

### Analogy

Think of `(* synthesize *)` like a **“highlight” tag**:
> "Hey compiler, I actually want to use this module in hardware — not just for typechecking."

Without it, the compiler skips code generation, treating it like unused notes in the margins.

```bsv
(* synthesize *)
module mkAdder(...);
    ...
endmodule
```

> [!NOTE]
> If you forget to mark your testbench with (* synthesize *), don’t be surprised when Bluesim gives you an error or doesn't simulate anything!

---

## Interface Declaration — Components

- **Interface Name**: The identifier for the interface (e.g., `Foo_IFC`)
- **Type Parameters**: Allows the interface to be generic over types and values
- **Action Methods**: Perform actions but don’t return a value
- **ActionValue Methods**: Perform actions and return a value
- **Value Methods**: Return a value without performing any action (pure)
- **Sub-interface Declarations**: Interfaces inside interfaces; supports hierarchical design

![interface_declaration](/images/interface_declaration.png)

---

## Module Declaration — Components

- **Module Name and Parameters**: Name of the module and optional parameters for configuration
- **Module Interface**: The interface the module implements (e.g., `Foo_IFC`)
- **Value Declarations**: Constants and register definitions
- **Module Instantiations**: Instantiating other modules inside this module
- **Function Declarations**: Local helper functions
- **Rules**: Behavioral blocks that describe how state changes occur
- **Method Definitions**: Implementation of the interface’s methods
- **Sub-interface Implementations**: Wiring up of sub-interfaces declared in the interface

![module_declaration](/images/module_declaration.png)

---

## Rule — Components

- **Rule Name**: Identifier for the rule
- **Rule Condition**: A `Bool` expression that guards the rule (must have no side effects)
- **Value Definitions**: Temporary variables, computed values (single assignment)
- **Actions**: Statements that mutate state (e.g., register updates, enqueues)
- **Note**: Rule body must evaluate to an `Action`. Can include conditionals and loops.

![rules](/images/package.png)

---

## Method Definition — Components

- **Method Name**: Identifier for the method
- **Method Condition**: Optional guard (`Bool` expression) controlling method availability
- **Value Definitions**: Local temporary values
- **Actions**: Executed in `Action` and `ActionValue` methods only
- **Return Statement**: Required in `Value` and `ActionValue` methods
- **Note**: Method body must evaluate to an `Action`, `ActionValue`, or pure value — depending on method type. No side effects in conditions.

![method_def](/images/method_def.png)

---

## Circuit Structure and Module Hierarchy

- A BSV design is structured as a **module hierarchy**, just like Verilog or SystemVerilog.
- The **leaf modules** are often **primitive state elements** (e.g., `Reg`, `FIFO`), but unlike Verilog, **even registers are modules** in BSV.

![circuit_struct](/images/circuit_struct.png)

---

## Rules and Interface Methods

- Every module exposes **an interface**, which defines **methods** for communication.
- **Modules contain rules**, which can invoke methods from other modules.
- **All inter-module interaction** is done via **method calls** — similar to object-oriented programming.
- Methods themselves can also call other methods — allowing **compositional** behavior.

![rules_and_method](/images/rules_and_method.png)

---

## Registers Are Modules

- Registers implement a simple interface:
  - `_read()` for reading the value
  - `_write(t)` for writing a value of type `t`
- You can access them in multiple convenient ways:
  - `x._write(x << 1);` — explicit
  - `x <= x << 1;` — preferred syntax using `<=`, which is shorthand for `_write()`

```bsv
interface Reg #(t);
 method Action _write (t v); // “t” is “int” or “Bool” or some other type
 method t _read ();
endinterface: Mult_ifc

x._write (x._read () << 1); // register update

x._write (x << 1); // shorthand for _write() as talked earlier

x <= x << 1; // further convenience
```

---

## Module Instantiation Syntax

- General form:
`interface_type instance_name <- module_name(module_parameters);`


### Examples:
- `Mult_ifc m <- mkMult;` — Module with no parameters
- `Reg#(int) w <- mkRegU;` — Uninitialized register
- `Reg#(Bool) got_x <- mkReg(False);` — Bool register with initial value

> [!NOTE]
> `mkRegU` creates a register without a defined reset value, whereas `mkReg(val)` initializes it with a specific value.

---

## Interfaces: Introduction

- **All communication between modules** in BSV happens through **interface methods**
- BSV follows a **transactional** or **object-oriented** model — unlike traditional HDLs with `input`/`output` signals
- Every module **provides an interface**, and other modules invoke its **methods** to interact
- An interface is always defined using an **explicit type** (e.g., `FIFO#(int)`)
- **Methods** behave like **rules**:
  - They have conditions
  - They can perform actions
  - They execute atomically when invoked

> [!NOTE]
> Interfaces are not just syntactic sugar — they’re a core organizational tool that enables **modular**, **reusable**, and **composable** designs.


## Key Benefits of Using Interfaces

- Improves **encapsulation**: separates implementation from how others interact with the module
- Promotes **reusability**: generic interfaces can be reused across designs (e.g., FIFOs, registers, buses)
- Aids **composability**: large designs can be built hierarchically using clean, type-safe module connections

![modules&interfaces](/images/modules&interfaces_example.png)

---

## Types of Methods in BSV

In BSV, methods are classified based on their return types:

| Method Type       | Description                                                                 | Example   |
|-------------------|-----------------------------------------------------------------------------|-----------|
| **Value Method**  | - Purely combinational (no side-effects)  <br> - Can be used anywhere       | `first`   |
| **Action Method** | - Has side-effects <br> - Returns nothing <br> - Can only be used in rules or other action-based methods | `enq`     |
| **ActionValue**   | - Has side-effects **and** returns a value <br> - Used like a function call with side-effect | `pop`     |

> [!NOTE]
> Rule and method conditions must always be **pure** — i.e., they cannot contain side-effects. Therefore, **only Value methods** can be used inside conditions.

---

## Example Interface: FIFO with Pop

```bsv
interface FIFOwPop #(type t);
  method Action enq(t x);                 // Action method
  method t first;                         // Value method
  method ActionValue#(t) pop;             // ActionValue method
endinterface
```

![action_value](/images/action_value_code.png)

```bsv
rule r1 (...);
  int x <- f1.pop;        // ActionValue: pops and returns a value
  f2.enq(x + 2);          // Action: side-effect only
endrule
```

> `x <- f1.pop` is similar to dynamic execution: it does something (pop) and returns a value. `f1 <- mkFIFOwPop` is similar to static elaboration: it builds a module and returns its interface. 

---

## Defining Methods in Modules

- Methods are always defined at the **end of the module body**
- An optional `if` condition in a method becomes its **implicit condition**
- This implicit condition becomes **part of any rule or method** that calls it
- The method's **action logic gets inlined** into the rule that invokes it

![method_defn](/images/method_defn.png)

---

## Interfaces = Modular Rules

- **Methods behave like rule fragments**
  - When a rule invokes a method, both the **condition and action** of the method are treated as part of the rule

- **Interfaces help modularize large behavior**
  - Instead of writing all logic inside a single rule or module, behavior is broken into methods
  - Promotes better structure, reuse, and clarity

> [!TIP]
> BSV interfaces don't introduce new semantics — they’re just a clean, powerful way to organize rules and logic into modular, composable units.

---

## Variables and “Single Assignment” in BSV

- In BSV, variables represent **immutable values** — like in mathematics.
- Unlike C/C++/Verilog where a variable refers to a storage location that can change over time, **BSV variables do not change once assigned**.
- All dynamic updates (e.g., to registers or memories) must be done via **Actions**.
- Multiple `=` assignments to the same name are just **syntactic sugar** — the compiler treats them as new variables (SSA form).
- This is known as **Static Single Assignment (SSA)**, common in functional languages and compilers.

> BSV separates *computation of values* from *updates to state*. This leads to clearer, more analyzable designs.

```bsv
int a = 10;
if (b) a = a + 1;
else a = a + 2;
if (c) a = a + 3;

int a = 10;
for (int k = 20; k < 24; k = k+1)
 a = a + k; // Ordinary variable assignment: =
```

---

## Assignment Symbols in BSV

| Symbol | Meaning                        | Example                                       | Notes                                                   |
|--------|--------------------------------|-----------------------------------------------|---------------------------------------------------------|
| `=`    | Static (pure) assignment       | `Int#(124) b = myMemory.lookup(addr);`        | No hardware created, value is fixed once assigned       |
| `<=`   | Register write (Action)        | `myRegA <= 32;`                                | Shorthand for `_write` method                           |
| `<-`   | Module instantiation or ActionValue binding | `Reg#(Bit#(32)) r <- mkReg(0);` <br> `let x <- myFIFO.pop;` | Top-level: instantiation <br> In rule: gets value from method with side-effect |

---

## `let` Syntax

```bsv
let x = 24'h9BEEF;
let y = x + 3;
let z = MyStruct { memberA: exprA, memberB: exprB };
```
> [!NOTE]
> `let` declares and initializes a variable with type inference. The compiler deduces the type from the right-hand side. Equivalent to declaring a type + assigning a value, but less cluttered.

> [!TIP]
> Use let when the type is obvious or not needed explicitly.

---

## Functions in BSV

```bsv
function int discr(int a, int b, int c);
  return b*b - 4*a*c;
endfunction
```

> [!NOTE]
> Functions in BSV are purely static, there is no runtime behavior: no stack, no call/return — they’re expanded inline during compilation. Think of them as circuit macros — whenever you call a function, its logic is plugged in place. Use functions for reusing pure computation, not for updating state or sequencing logic.