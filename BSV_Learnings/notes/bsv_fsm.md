# StmtFSM in Bluespec

## Overview

`StmtFSM` is a facility in BSV for expressing structured, rule-based processes using a higher-level FSM DSL. While traditional FSMs can be written directly with rules, `StmtFSM` offers a **more readable** and **structured** alternative.

---

## Motivation

- FSMs are common in hardware designs.
- Traditional encoding in BSV uses `Reg` + `Rules` to represent states and transitions.
- Example:

```bsv
typedef enum { S0, S1, S2, ... } State deriving (Bits, Eq);
module mkFoo (...);
  Reg#(State) state <- mkReg(S0);

  rule r0 (state == S0);
    ... do state S0 actions ...
    state <= S1;
  endrule

  rule r1 (state == S1);
    ... do state S1 actions ...
    state <= (some_cond ? S1 : S2);
  endrule

  rule r2 (state == S2);
    ... do state S2 actions ...
  endrule
endmodule
```

> Verbose and error-prone for large FSMs.

---
## Using `StmtFSM`

To define FSMs more concisely:

1. `import StmtFSM :: *;`
2. Create a `Stmt` (FSM specification).
3. Instantiate using `mkFSM(stmt)`, which returns an `FSM` interface.
4. Control execution with `start`, `done`, `waitTillDone`, and `abort`.

```bsv
interface FSM;
  method Action start;
  method Bool done;
  method Action waitTillDone;
  method Action abort;
endinterface
```

> [!NOTE]
> `done`: Boolean to check if FSM has finished; - `waitTillDone`: Action that blocks until FSM finishes; `abort`: Force FSM to reset to its initial state. 

---

## Example FSM with `StmtFSM`

```bsv
import StmtFSM :: *;

module mkFoo (...);
  Stmt stmt = seq
    ... state S0 actions ...
    while (some_cond) ... state S1 actions ...
    ... state S2 actions ...
  endseq;

  FSM fsm <- mkFSM(stmt);

  rule init (...);
    fsm.start;
  endrule

  rule done (fsm.done);
    ...
  endrule
endmodule
```

### Alternate Loop Form

```bsv
while (True) seq
  ... do state S1 actions ...
  if (some_cond) break;
endseq
```

---

## FSM Composition

- FSMs can be **composed** via `Stmt` blocks.
- Every FSM has a well-defined **start** and **done**. 
- Composition is done with sequencing, loops, conditionals, and parallel blocks.

### Syntax

|Construct|Description|
|---|---|
|`seq a1; a2; ... endseq`|Linear sequencing|
|`if (cond) fsm1 [else fsm2]`|Conditionals|
|`for (...) fsm1` / `while (...) fsm1` / `repeat (...) fsm1`|Loops|
|`par fsm1; fsm2; ... endpar`|Parallel composition|

>[!NOTE]
>`break` and `continue` work as expected in loops.  `action ... endaction` wraps multiple operations atomically.

---

## Example: Parallel FSMs

```bsv
Stmt specfsm = seq
  write(15, 51);
  read(15);
  ack;
  ack;
  write(16, 61);
  write(17, 71);

  action
    read(16);
    ack;
  endaction

  action
    read(17);
    ack;
  endaction

  ack;
  ack;
endseq;

FSM testfsm <- mkFSM(specfsm);

rule run (True);
  testfsm.start;
endrule

rule done (testfsm.done);
  $finish(0);
endrule
```

> `action ... endaction` blocks group atomic actions into one rule.

## FSM as Testbench Stimulus Generator

```bsv
Stmt test_seq = seq
  for (i <= 0; i < NI; i <= i + 1)
    for (j <= 0; j < NJ; j <= j + 1) action
      let pkt <- gen_packet();
      send_packet(i, j, pkt);
    endaction

  action
    send_packet(0, 1, pkt0); // to dest 1
    send_packet(1, 1, pkt1); // collision at dest 1
  endaction
endseq;

mkAutoFSM(test_seq);
```

`mkAutoFSM` Module

```bsv
module mkAutoFSM #(Stmt s) (Empty);
  FSM fsm <- mkFSM(s);

  rule rA:
    fsm.start;
  endrule

  rule rB (fsm.done);
    $finish;
  endrule
endmodule
```

> Automatically starts and finishes FSM,  useful for testbenches.

![tb](/images/tb.png)

## Suspendable FSMs

Use `mkFSMWithPred` to enable external pause/resume:

```bsv
module mkFSMWithPred #(Stmt s, Bool b) (FSM);
```

> FSM execution gated by predicate `b`, adds **asynchronous external control**, supports parallelism, abort, nesting — similar to **Esterel-style FSMs**.

## FSM Servers

FSM Servers allow multi-cycle client-server protocols to look like simple procedure calls.

```bsv
Stmt s = seq
  mem.request.put(Req { op: Load, addr: a });
  let response <- mem.response.get;
endseq;
```

>[!NOTE]
>Without FSM server: requires split-phase FSM manually.
>
>With FSM server:

```bsv
function RStmt#(Data) fn_memServer (Req req);
  seq
    ... read memory logic ...
    return data;
  endseq
endfunction

FSMServer#(Addr, Data) memServer <- mkFSMServer(fn_memServer);

Stmt s = seq
  response <- callServer(memServer, Req { op: Load, addr: a });
endseq;
```

> `RStmt` is like `Stmt` with `return` values, enables high-level "function-like" usage of multi-cycle protocols.

---

## Summary

|Feature|Description|
|---|---|
|`StmtFSM`|DSL for structured FSMs in BSV|
|`mkFSM`|Compiles a `Stmt` into an `FSM` interface|
|`mkAutoFSM`|Automatically runs an FSM and calls `$finish`|
|`mkFSMWithPred`|FSM controlled by external predicate|
|`mkFSMServer`|Allows server-like, blocking-call semantics for FSMs|

> If you wanna explain in one line - Powerful abstraction that simplifies FSM design and enables expressive testbenches and multi-cycle protocol handling.