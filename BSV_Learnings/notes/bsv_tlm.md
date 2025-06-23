# Transaction-Level Modeling (TLM) in Bluespec

## Overview

Transaction-Level Modeling (TLM) refers to a style of using high-level communication interfaces—like `Get/Put` and `Client/Server`—to simplify module interconnection. These stylized interfaces improve:

- Readability
- Maintainability
- Modularity
- Hardware clarity (no synthesis cost)

>  BSV has supported this modeling style since 2000, and it's used in production synthesis—not just simulation!

---

## Get/Put Interfaces

Instead of writing ad hoc methods in interfaces, use standard interfaces defined in the BSV library:

```bsv
interface Get#(type t);
  method ActionValue#(t) get();
endinterface

interface Put#(type t);
  method Action put(t x);
endinterface
```

These interfaces describe communication protocols and signals; the module defines the logic.

### Example: Cache Interface using Get/Put

```bsv
interface CacheIfc;
  interface Put#(Req_t) p2c_request;
  interface Get#(Resp_t) c2p_response;
endinterface

module mkCache (CacheIfc);
  FIFO#(Req_t) p2c <- mkFIFO;
  FIFO#(Resp_t) c2p <- mkFIFO;

  interface p2c_request;
    method Action put (Req_t req);
      p2c.enq(req);
    endmethod
  endinterface

  interface c2p_response;
    method ActionValue#(Resp_t) get();
      let resp = c2p.first;
      c2p.deq;
      return resp;
    endmethod
  endinterface
endmodule
```

---

## Interface Transformers

We can simplify interface logic by transforming FIFOs into standard interfaces.

### Transformer Functions

```bsv
function Put#(Req_t) toPut (FIFO#(Req_t) fifo);
  return (
    interface Put;
      method Action put (Req_t x);
        fifo.enq(x);
      endmethod
    endinterface
  );
endfunction

function Get#(Resp_t) toGet (FIFO#(Resp_t) fifo);
  return (
    interface Get;
      method ActionValue#(Resp_t) get();
        let a = fifo.first;
        fifo.deq;
        return a;
      endmethod
    endinterface
  );
endfunction
```
>  These are overloaded via `ToPut` and `ToGet` typeclasses. No runtime overhead.

### Simplified Cache Using Transformers

```bsv
module mkCache (CacheIfc);
  FIFO#(Req_t) p2c <- mkFIFO;
  FIFO#(Resp_t) c2p <- mkFIFO;

  interface p2c_request = toPut(p2c);
  interface c2p_response = toGet(c2p);
endmodule
```

---

## Client/Server Interfaces

Interfaces can be nested. The BSV library provides client/server abstractions:

```bsv
interface Client #(req_t, resp_t);
  interface Get#(req_t) request;
  interface Put#(resp_t) response;
endinterface

interface Server #(req_t, resp_t);
  interface Put#(req_t) request;
  interface Get#(resp_t) response;
endinterface
```

### Cache Example Using Client/Server

```bsv
interface CacheIfc;
  interface Server#(Req_t, Resp_t) ipc;
  interface Client#(Req_t, Resp_t) icm;
endinterface

module mkCache (CacheIfc);
  FIFO#(Req_t) p2c <- mkFIFO;
  FIFO#(Resp_t) c2p <- mkFIFO;
  FIFO#(Req_t) c2m <- mkFIFO;
  FIFO#(Resp_t) m2c <- mkFIFO;

  interface Server ipc;
    interface Put request = toPut(p2c);
    interface Get response = toGet(c2p);
  endinterface

  interface Client icm;
    interface Get request = toGet(c2m);
    interface Put response = toPut(m2c);
  endinterface
endmodule
```

### Even Simpler with Transformers

```bsv
interface Server ipc = toGPServer(p2c, c2p);
interface Client icm = toGPClient(c2m, m2c);
```

---

## mkConnection: Connecting Interfaces

To link `Get` and `Put` interfaces, define a rule:

```bsv
module mkTop (...);
  Get#(int) m1 <- mkM1;
  Put#(int) m2 <- mkM2;

  rule connect;
    let x <- m1.get();
    m2.put(x);
  endrule
endmodule
```

### Capturing This Pattern: `mkConnectionGetPut`

```bsv
module mkConnectionGetPut #(Get#(t) g, Put#(t) p) (Empty);
  rule connect;
    let x <- g.get();
    p.put(x);
  endrule
endmodule

module mkTop (...);
  Get#(int) m1 <- mkM1;
  Put#(int) m2 <- mkM2;
  mkConnectionGetPut(m1, m2);  // Cleaner
endmodule
```

---

## Generalizing Connections with Typeclasses

BSV allows interface overloading via **typeclasses**.

```bsv
typeclass Connectable #(type t1, type t2);
  module mkConnection #(t1 m1, t2 m2) (Empty);
endtypeclass
```

### Get/Put Instance

```bsv
instance Connectable #(Get#(t), Put#(t));
  module mkConnection #(Get#(t) m1, Put#(t) m2) (Empty);
    rule r;
      let x <- m1.get;
      m2.put(x);
    endrule
  endmodule
endinstance
```

> This pattern is extensible: `Client/Server`, `AXI Master/Slave`, `TLM Master/Slave`, etc.

---
## Final Example: Top-Level Connections

```bsv
interface CacheIfc;
  interface Server#(Req_t, Resp_t) ipc;
  interface Client#(Req_t, Resp_t) icm;
endinterface

module mkTopLevel (...);
  Client#(Req_t, Resp_t) p <- mkProcessor;
  CacheIfc c <- mkCache;
  Server#(Req_t, Resp_t) m <- mkMem;

  mkConnection(p, c.ipc);
  mkConnection(c.icm, m);
endmodule
```

> The entire processor-cache-memory system connects cleanly in **just 5 lines** of top-level code!

## Summary

- **Get/Put** and **Client/Server** provide reusable communication patterns.
- Use **interface transformers** like `toPut`, `toGet`, `toGPClient`, etc. to simplify design.
 - **mkConnection** and the **Connectable** typeclass allow automatic interface linkage with clean syntax.
 - TLM isn't just for simulation—it's practical, synthesizable, and elegant in production RTL.

---

> [!NOTE]
> Related Typeclasses - `Connectable`,  `ToPut`, `ToGet`, `ToGPClient`, `ToGPServer`. Use these to write modular, abstract, and reusable hardware in BSV.