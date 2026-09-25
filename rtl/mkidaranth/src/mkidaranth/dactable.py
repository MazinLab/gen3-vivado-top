from amaranth import *
from amaranth.lib import wiring, stream, data
from amaranth.utils import exact_log2

from mkidaranth.utils import Complex
from mkidaranth.primitives.uram import UltraRAMColumn


class SubTable(wiring.Component):
    enable:  wiring.In(1)

    wen:     wiring.In(1)
    waddr:   wiring.In(exact_log2(4096 * 4))
    wdata:   wiring.In(256)

    o: wiring.Out(stream.Signature(data.StructLayout({
        "iq":   data.ArrayLayout(Complex(16), 8),
        "id":   2,
        "last": 1
    }), always_ready=True))

    def __init__(self, id):
        self._id = id
        super().__init__()

    def elaborate(self, platform):
        m = Module()

        self._rams = rams = [UltraRAMColumn(4) for _ in range(4)]

        address = Signal.like(self.waddr)
        counter = Signal.like(self.waddr)
        with m.If(self.enable):
            m.d.sync += address.eq(address + 1)
        with m.If(rams[0].b.data_read_valid):
            m.d.sync += counter.eq(counter + 1)

        m.d.sync += self.o.valid.eq(rams[0].b.data_read_valid)
        m.d.sync += self.o.p.id.eq(self._id)
        with m.If(counter == (4096 * 4) - 1):
            m.d.sync += self.o.p.last.eq(1)
        with m.Else():
            m.d.sync += self.o.p.last.eq(0)

        for i, ram in enumerate(rams):
            m.submodules[f"ram{i}"] = ram

            m.d.sync += [
                ram.a.en  .eq(self.wen),
                ram.a.wr  .eq(self.wen),
                ram.a.we  .eq(0x1ff),
                ram.a.addr.eq(self.waddr),
                ram.a.data_write.eq(self.wdata[64 * i: 64 * (i + 1)]),

                ram.b.en.eq(self.enable),
                ram.b.addr.eq(address),
            ]

            for j in range(2):
                m.d.sync += [
                    self.o.p.iq[i * 2 + j].eq(ram.b.data_read[j * 32 : (j + 1) * 32])
                ]

        return m


class Table(wiring.Component):
    mask:   wiring.In(range(4))
    select: wiring.In(range(4))
    enable: wiring.In(1)

    wen:    wiring.In(1)
    waddr:  wiring.In(exact_log2(4096 * 4 * 4))
    wdata:  wiring.In(256)

    o: wiring.Out(stream.Signature(data.StructLayout({
        "iq":   data.ArrayLayout(Complex(16), 8),
        "id":   2,
        "last": 1,
    }), always_ready=True))

    def elaborate(self, platform):
        m = Module()

        table = Signal.like(self.mask)

        self._subtables = subtables = [SubTable(i) for i in range(4)]
        for i, t in enumerate(subtables):
            m.submodules[f"table{i}"] = t
            m.d.comb += t.enable.eq(self.enable)
            with m.If(i == (self.mask & table) | self.select):
                wiring.connect(m, t.o, wiring.flipped(self.o))

            m.d.sync += [
                t.waddr.eq(self.waddr),
                t.wdata.eq(self.wdata),
            ]
            with m.If(self.waddr[-2:] == i):
                m.d.sync += t.wen.eq(self.wen)

        with m.If(self.o.valid & self.o.ready & self.o.p.last):
            m.d.sync += table.eq(table + 1)

        return m
