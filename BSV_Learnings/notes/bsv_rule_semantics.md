# Rule Execution Semantics in BSV

## First Approximation

Each rule has two key parts:
- A **CAN_FIRE** condition (of type `Bool`)
- A **Composite Action** (all actions in the rule body)

If `CAN_FIRE` is true → execute the rule body.

**CAN_FIRE** is the conjunction of:
- The explicit rule condition  
- Method conditions used in the rule condition  
- Method conditions of all methods invoked in the rule body

---

## 1. Semantics of a Single Rule (Parallelism)

- All actions in a rule execute simultaneously as a single atomic block — there’s no implied ordering.
- **No ordering** among actions — they are treated as **parallel**
- Reads see old values (from the previous cycle)
- Writes become visible only **after** the rule fires
- Actions may be gated by local `if` conditions

> The rule body is an atomic action block: all actions happen simultaneously if enabled.

### Invalid Cases (compiler errors):
| Case | Reason |
|------|--------|
| Writing two values to the same register | Multiple updates not allowed |
| Two enqueues to the same FIFO | FIFO has only one enqueue port |
| Two reads from a single-port regfile | Only one read allowed |

---

## 2. Semantics of Multiple Rules (Concurrency)

- All rules are placed in a linear **schedule** by the compiler:
`r1, r2, r3, ..., rN`

- Rule `rJ` fires if:
  - `CAN_FIRE_rJ` is true
  - No conflicts with earlier rules (`r1 .. rJ-1`)

> The compiler inserts logic to disable later rules if they conflict with earlier ones in the schedule.

---

## Method Ordering Constraints

### How method calls from different rules may interact:

| Constraint | Meaning |
|-----------|---------|
| `mA conflict_free mB` | Can fire concurrently in any order |
| `mA < mB` | Can fire if rule with `mA` is before rule with `mB` |
| `mB < mA` | Can fire if rule with `mB` is before rule with `mA` |
| `mA conflict mB` | Cannot fire concurrently at all |

### Examples:
- **mkReg**: `_read < _write`
- **mkFIFO**:
  - `{deq, first} conflict`
  - `enq conflict enq`
- **mkPipelineFIFO**:
  - `{deq, first} < enq`

---

## Conflicts Between Rules

- A conflict exists if **any pair of method calls** from two rules violate ordering constraints
- In such cases, the earlier rule disables the later rule:

```bsv
WILL_FIRE_r2 = (!WILL_FIRE_r1) && CAN_FIRE_r2
```

## Scheduling

- The compiler chooses a **rule schedule** that:
  - **Maximizes concurrency**
  - **Minimizes conflicts**
- Total possible schedules = `N!` for `N` rules
- Compiler may emit informational messages when the choice is **arbitrary**

---

## Logical vs Implementation Semantics

| View           | Meaning                                                |
|----------------|--------------------------------------------------------|
| **Logical**     | Rule semantics, single-instant firing, no hardware details |
| **Implementation** | Generated Verilog may reorder, pipeline, etc. but obeys logical behavior |

**Analogy:**

- Assembly (logical): one instruction at a time  
- CPU (implementation): out-of-order, pipelined, superscalar, etc.

---

## Rule Semantics Summary

- All rules are evaluated in a **compiler-chosen schedule**
- A rule fires in a clock cycle if:
  - Its `CAN_FIRE` is `true`
  - It **does not conflict** with any earlier rule in the schedule

If it fires:
- All actions in the rule body execute **atomically and in parallel**

> The compiler automatically inserts logic to disable later rules in case of conflicts.

---

# Controlling Rule Scheduling in BSV

## Compiler Scheduling Behavior
- The BSV compiler (`bsc`) chooses a **schedule** (linear rule ordering) to:
  - Maximize rule concurrency
  - Minimize conflicts
- Total rule orderings = `N!` for `N` rules

---

## Attributes for User-Controlled Scheduling

### 🔹 Attribute Syntax
```bsv
(* attribute = "rule1, rule2, ..." *)
```
Placed inside a module, before the relevant rules or methods.

---

## Rule Urgency

### 🔸 What It Is
- Controls **priority** of rule firing.
- Affects **WILL_FIRE** computation.

### 🔸 Example
```bsv
(* descending_urgency = "r1, r2" *)
```
- If both `r1` and `r2` try to `fifo.enq()`, and `r1` can fire, then `r2` is suppressed.

---

## Rule Preempts

### 🔸 What It Is
- Forces one rule (`r1`) to always suppress another (`r2`) if it fires, **even without conflict**.
- Equivalent to **inserting a conflict** manually.

### 🔸 Example
```bsv
(* preempts = "r1, r2" *)
```
- If `r1` fires, `r2` is **disabled**, regardless of its `CAN_FIRE`.

---

## Rules Are Mutually Exclusive

### 🔸 What It Is
- Tells the compiler that two rules **cannot be true at the same time**.
- Helps generate **simpler hardware** (e.g., priority-free muxes).

### 🔸 Example
```bsv
(* mutually_exclusive = "updateBit0, updateBit1" *)
```

- Compiler will **insert runtime checks** in simulation.
- Can improve synthesis even when mutual exclusivity can't be proven.

---

## Rule Execution Semantics: A Refinement

Each rule involves:
1. **Condition evaluation** (pure, no side effects)
2. **Body execution** (state updates)

Because of this, BSV refines rule ordering into:

### 🔹 Urgency Order
- Determines order of **condition evaluation**

### 🔹 Execution Order (Earliness)
- Determines order of **rule body execution**

---

## Controlling Execution Order

### 🔸 What It Is
- Forces order of **rule body execution**, regardless of conflicts.

### 🔸 Example
```bsv
(* execution_order = "r1, r2" *)
```

---

## Example: Urgency vs Execution Order

```bsv
(* descending_urgency = "enq_item, enq_bubble" *)
rule enq_item;
  outfifo.enq(infifo.first); infifo.deq;
  bubbles <= 0;
endrule

rule inc_bubbles;
  bubbles <= bubbles + 1;
endrule

rule enq_bubble;
  outfifo.enq(bubble_value);
  max_bubbles <= max(max_bubbles, bubbles);
endrule
```

### Explanation:
- **Execution order (earliness):**
  - `enq_bubble < inc_bubbles < enq_item`  
  - Ensures correct dataflow (read before write)
- **Urgency order:**
  - `enq_item < enq_bubble`  
  - Prioritizes real items over bubbles when both are available

---

>  [!Tip]
> Always use attributes carefully. Poorly specified rule orderings can reduce concurrency or introduce hidden bugs.