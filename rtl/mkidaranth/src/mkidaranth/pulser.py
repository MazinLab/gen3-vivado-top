from amaranth import *
from amaranth.lib import stream, wiring, data, enum, fifo
from amaranth.lib.wiring import In, Out

from amaranth_soc import csr
from . import trigger_peripheral
from .axi import bus, ip
from .axi.stream import StreamPipelineStage

from .utils import Complex, CMultiply


class PulseCommand(data.Struct):
    class Command(enum.Enum, shape=4):
        SET = 0
        DELAY = 1
        SYNC = 2
        OUTP = 3
        CMUL = 4

    command: Command
    info: data.UnionLayout({
        "set": data.StructLayout({"shr": data.ArrayLayout(unsigned(4), 8)}),
        "delay": data.StructLayout({"delay": unsigned(32)}),
        "sync": data.StructLayout({"sources": unsigned(32)}),
        "outp": data.StructLayout({"outp": unsigned(32)}),
        "cmul": Complex(16),
    })


class Pulser(wiring.Component):
    iin: In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))
    qin: In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))

    iout: Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))
    qout: Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))

    command: In(stream.Signature(PulseCommand))
    sync: In(32)
    outp: Out(32)

    def elaborate(self, platform):
        m = Module()

        delay_loaded = Signal()
        delay = Signal(28)
        shrs = [Signal(4) for _ in range(8)]
        sync_last = Signal()

        qam_mod = Signal(Complex(16))

        cmuls = []
        for i in range(8):
            m.submodules[f"cmul{i}"] = cmul = CMultiply(16, 16)
            m.d.sync += [
                cmul.a.valid.eq(self.iin.valid),
                cmul.a.payload.real.eq(self.iin.payload[i] >> shrs[i]),
                cmul.a.payload.imag.eq(self.qin.payload[i] >> shrs[i]),
                cmul.b.valid.eq(1),
                cmul.b.payload.eq(qam_mod),
                self.iout.payload[i].eq(cmul.p.payload.real.shift_right(15)),
                self.qout.payload[i].eq(cmul.p.payload.imag.shift_right(15)),
                self.iout.valid.eq(cmul.p.valid),
                self.qout.valid.eq(cmul.p.valid),
            ]
            cmuls.append(cmul)

        m.d.sync += [
            sync_last.eq(self.sync),
        ]

        with m.If(self.command.valid):
            with m.If(self.command.payload.command == PulseCommand.Command.SET):
                m.d.sync += [shrs[i].eq(self.command.payload.info.set.shr[i]) for i in range(8)]
                m.d.comb += self.command.ready.eq(1)
            with m.If(self.command.payload.command == PulseCommand.Command.DELAY):
                m.d.sync += delay.eq(delay - 1)
                with m.If(~delay_loaded):
                    m.d.sync += [delay_loaded.eq(1), delay.eq(self.command.payload.info.delay.delay - 2)]
                with m.If((delay == 0) & delay_loaded):
                    m.d.comb += self.command.ready.eq(1)
                    m.d.sync += delay_loaded.eq(0)
            with m.If(self.command.payload.command == PulseCommand.Command.SYNC):
                with m.If(
                    (self.sync & self.command.payload.info.sync.sources)
                    & (~(sync_last & self.command.payload.info.sync.sources))
                ):
                    m.d.comb += self.command.ready.eq(1)
            with m.If(self.command.payload.command == PulseCommand.Command.OUTP):
                m.d.sync += self.outp.eq(self.command.payload.info.outp.outp)
                m.d.comb += self.command.ready.eq(1)
            with m.If(self.command.payload.command == PulseCommand.Command.CMUL):
                m.d.comb += self.command.ready.eq(1)
                m.d.sync += qam_mod.eq(self.command.payload.info.cmul)

        return m


class PulserPeripheral(wiring.Component):
    class CommandFIFO(csr.Register, access="rw"):
        command: csr.Field(csr.action.W, PulseCommand)

    class CommandFIFOStatus(csr.Register, access="rw"):
        depth: csr.Field(csr.action.R, 16)
        count: csr.Field(csr.action.R, 16)
        lowmark: csr.Field(csr.action.W, 16)

    def __init__(self, fifo_depth):
        assert fifo_depth < (1 << 16)
        self.fifo_depth = fifo_depth

        regs = csr.Builder(addr_width=8, data_width=32)
        self._cfifo = regs.add("CommandFIFO", self.CommandFIFO())
        self._cfifo_stat = regs.add("CommandFIFOStatus", self.CommandFIFOStatus())
        self._bridge = csr.Bridge(regs.as_memory_map())

        super().__init__({
            "interrupt": Out(1),
            "ctlbus": In(csr.Signature(addr_width=8, data_width=32)),
            "iin": In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
            "qin": In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
            "iout": Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
            "qout": Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
            "pps": In(1),
            "sync": In(31),
            "outp": Out(32),
        })

        self.ctlbus.memory_map = self._bridge.bus.memory_map

    def elaborate(self, platform):
        m = Module()

        m.submodules.bridge = self._bridge
        wiring.connect(m, wiring.flipped(self.ctlbus), self._bridge.bus)

        m.submodules.pipeline = pipeline = StreamPipelineStage(36)
        m.submodules.command_fifo = command_fifo = fifo.SyncFIFOBuffered(width=36, depth=self.fifo_depth)
        m.d.comb += {
            command_fifo.w_data.eq(self._cfifo.f.command.w_data),
            command_fifo.w_en.eq(self._cfifo.f.command.w_stb),
            self._cfifo_stat.f.depth.r_data.eq(self.fifo_depth),
            self._cfifo_stat.f.count.r_data.eq(command_fifo.level),
        }

        m.d.sync += self.interrupt.eq(command_fifo.level < self._cfifo_stat.f.lowmark.w_data)

        m.submodules.pulser = pulser = Pulser()
        wiring.connect(m, command_fifo.r_stream, pipeline.input)
        wiring.connect(m, pipeline.output, pulser.command)
        wiring.connect(m, wiring.flipped(self.iin), pulser.iin)
        wiring.connect(m, wiring.flipped(self.qin), pulser.qin)
        wiring.connect(m, wiring.flipped(self.iout), pulser.iout)
        wiring.connect(m, wiring.flipped(self.qout), pulser.qout)
        m.d.comb += pulser.sync.eq(Cat(self.pps, self.sync))
        m.d.comb += self.outp.eq(pulser.outp)

        return m


BUS_PROPS = bus.Axi4LiteProperties(DATA_WIDTH=32, ADDR_WIDTH=10)


class PulserIntegration(wiring.Component):
    aclk: In(1)
    aresetn: In(1)
    interrupt: Out(1)

    s_axi_pulser: In(bus.StandardizedAxiSignature(BUS_PROPS))
    s_axis_iin: In(bus.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)))
    s_axis_qin: In(bus.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)))
    m_axis_iout: Out(bus.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)))
    m_axis_qout: Out(bus.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)))

    pps: In(1)
    sync: In(31)
    outp: Out(32)

    def elaborate(self, platform):
        m = Module()

        if not platform is None:
            m.domains.sync = cd_sync = ClockDomain()
            m.d.comb += [cd_sync.clk.eq(self.aclk), cd_sync.rst.eq(~self.aresetn)]

        m.submodules.pipea = pipea = bus.AxiPipelineStage(BUS_PROPS)
        m.submodules.pipeb = pipeb = bus.AxiPipelineStage(BUS_PROPS)
        bus.connect_axi(m, wiring.flipped(self.s_axi_pulser), pipea.input)
        wiring.connect(m, pipea.output, pipeb.input)

        m.submodules.converter = converter = ip.AXICSRBridge(addr_width=10, data_width=32)
        self.pulser_peri = m.submodules.pulser_peri = pulser_peri = PulserPeripheral(4096)

        wiring.connect(m, pipeb.output, converter.axi)
        bus.connect(m, wiring.flipped(self.s_axis_iin), pulser_peri.iin)
        bus.connect(m, wiring.flipped(self.s_axis_qin), pulser_peri.qin)
        bus.connect(m, wiring.flipped(self.m_axis_iout), pulser_peri.iout)
        bus.connect(m, wiring.flipped(self.m_axis_qout), pulser_peri.qout)
        m.d.comb += pulser_peri.pps.eq(self.pps)
        m.d.comb += pulser_peri.sync.eq(self.sync)
        m.d.comb += self.outp.eq(pulser_peri.outp)
        m.d.sync += self.interrupt.eq(pulser_peri.interrupt)

        wiring.connect(m, converter.csr, pulser_peri.ctlbus)

        return m


if __name__ == "__main__":
    import sys
    from amaranth.back import verilog
    from amaranth.vendor import XilinxPlatform

    from .integration import map_to_json
    from .utils import RFSoCGen3Platform

    integrated_pulser = PulserIntegration()
    with open(sys.argv[1], "w") as f:
        f.write(verilog.convert(integrated_pulser, name="pulser_integraton", platform=RFSoCGen3Platform()))
    with open(sys.argv[1] + ".json", "w") as fj:
        fj.write(map_to_json(integrated_pulser.pulser_peri.ctlbus.memory_map))
