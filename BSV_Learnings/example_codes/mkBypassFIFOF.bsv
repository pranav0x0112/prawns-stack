module mkBypassFIFOF(FIFOF#(t));
  CReg #(3, t) crg <- mkCRegU;
  CReg #(3, Bit #(1)) crg_count <- mkCReg(0);

  method Bool notEmpty = (crg_count.ports[1] == 1);
  method Bool notFull  = (crg_count.ports[0] == 0);

  method Action enq(t x) if (crg_count.ports[0] == 0);
    crg.ports[0] <= x;
    crg_count.ports[0] <= 1;
  endmethod

  method t first() if (crg_count.ports[1] == 1);
    return crg.ports[1];
  endmethod

  method Action deq() if (crg_count.ports[1] == 1);
    crg_count.ports[1] <= 0;
  endmethod

  method Action clear;
    crg_count.ports[2] <= 0;
  endmethod
endmodule