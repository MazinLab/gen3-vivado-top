from amaranth import *
from amaranth.lib import wiring, stream, fifo
from amaranth.lib.wiring import In, Out

# Credit: Catherine, https://github.com/GlasgowEmbedded/glasgow/blob/main/software/glasgow/gateware/stream.py

class Queue(wiring.Component):
    def __init__(self, *, shape, depth, buffered=True):
        self._shape = shape
        self._depth = depth
        self._buffered = buffered

        super().__init__({
            "i": In(stream.Signature(shape)),
            "o": Out(stream.Signature(shape)),
            "level": Out(range(depth + 1))
        })

    def elaborate(self, platform):
        m = Module()

        fifo_cls = fifo.SyncFIFOBuffered if self._buffered else fifo.SyncFIFO
        m.submodules.inner = inner = fifo_cls(
            width=Shape.cast(self._shape).width,
            depth=self._depth
        )
        m.d.comb += [
            inner.w_data.eq(self.i.payload),
            inner.w_en.eq(self.i.valid),
            self.i.ready.eq(inner.w_rdy),
            self.o.payload.eq(inner.r_data),
            self.o.valid.eq(inner.r_rdy),
            inner.r_en.eq(self.o.ready),
            self.level.eq(inner.level),
        ]

        return m

class SkidBuffer(wiring.Component):
    def __init__(self, shape, depth):
        self._shape = shape
        self._depth = depth

        super().__init__({
            "i": In(stream.Signature(shape)),
            "o": Out(stream.Signature(shape)),
        })

    def elaborate(self, platform):
        m = Module()

        m.submodules.skid = skid = Queue(shape=self._shape, depth=self._depth, buffered=False)

        m.d.comb += skid.i.payload.eq(self.i.payload)
        m.d.comb += skid.i.valid.eq(self.i.valid & (~self.o.ready | skid.o.valid))
        with m.If(skid.o.valid):
            wiring.connect(m, wiring.flipped(self.o), skid.o)
        with m.Else():
            wiring.connect(m, wiring.flipped(self.o), wiring.flipped(self.i))

        return m