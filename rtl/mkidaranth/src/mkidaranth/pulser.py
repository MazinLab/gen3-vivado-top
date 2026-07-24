from amaranth import *
from amaranth.lib import stream, wiring, data, enum, fifo, memory
from amaranth.lib.wiring import In, Out

from amaranth_soc import csr
from . import trigger_peripheral, axi
from .trigger import StreamPipelineStage
from .axi import Axi4LiteProperties


class Complex(data.StructLayout):
    def __init__(self, bits):
        super().__init__({"real": signed(bits), "imag": signed(bits)})

# Ripped pretty much directly from UG901
class CMultiply(wiring.Component):
    def __init__(self, a_width, b_width):
        self.__a_width = a_width
        self.__b_width = b_width
        super().__init__(
            {
                "a": In(stream.Signature(Complex(a_width), always_ready=True)),
                "b": In(stream.Signature(Complex(b_width), always_ready=True)),
                "p": Out(stream.Signature(Complex(a_width + b_width + 1), always_ready=True)),
            }
        )

    def elaborate(self, platform):
        m = Module()
        a_delay = [Signal(Complex(self.__a_width)) for _ in range(4)]
        b_delay = [Signal(Complex(self.__b_width)) for _ in range(4)]
        v_delay = [Signal(1) for _ in range(5)]

        m.d.sync += (
            [
                a_delay[0].eq(self.a.payload),
                b_delay[0].eq(self.b.payload),
                v_delay[0].eq(self.a.valid & self.b.valid),
            ]
            + [a_delay[i].eq(a_delay[i - 1]) for i in range(1, 4)]
            + [b_delay[i].eq(b_delay[i - 1]) for i in range(1, 4)]
            + [v_delay[i].eq(v_delay[i - 1]) for i in range(1, 5)]
        )

        # Common Product
        add_common_1 = Signal(signed(self.__a_width + 1))
        mult_common_2 = Signal(signed(self.__a_width + self.__b_width + 1))
        mult_common_3 = Signal(signed(self.__a_width + self.__b_width + 1))
        mult_common_4 = Signal(signed(self.__a_width + self.__b_width + 1))
        m.d.sync += [
            add_common_1.eq(a_delay[0].real - a_delay[0].imag),
            mult_common_2.eq(add_common_1 * b_delay[1].imag),
            mult_common_3.eq(mult_common_2),
            mult_common_4.eq(mult_common_3),
        ]

        # Real Part
        add_real_3 = Signal(signed(self.__b_width + 1))
        mult_real_4 = Signal(signed(self.__a_width + self.__b_width + 1))
        m.d.sync += [
            add_real_3.eq(b_delay[2].real - b_delay[2].imag),
            mult_real_4.eq(add_real_3 * a_delay[3].real),
        ]

        # Imaginary Part
        add_imag_3 = Signal(signed(self.__b_width + 1))
        mult_imag_4 = Signal(signed(self.__a_width + self.__b_width + 1))
        m.d.sync += [
            add_imag_3.eq(b_delay[2].real + b_delay[2].imag),
            mult_imag_4.eq(add_imag_3*a_delay[3].imag)
        ]

        # Output
        m.d.sync += [
            self.p.payload.real.eq(mult_real_4 + mult_common_4),
            self.p.payload.imag.eq(mult_imag_4 + mult_common_4),
            self.p.valid.eq(v_delay[4]),
        ]
        return m


class PulseCommand(data.Struct):
    class Command(enum.Enum, shape=4):
        SET = 0
        DELAY = 1
        SYNC = 2
        OUTP = 3
        CMUL = 4

    command: Command
    info: data.UnionLayout(
        {
            "set": data.StructLayout({"shr": data.ArrayLayout(unsigned(4), 8)}),
            "delay": data.StructLayout({"delay": unsigned(32)}),
            "sync": data.StructLayout({"sources": unsigned(32)}),
            "outp": data.StructLayout({"outp": unsigned(32)}),
            "cmul": Complex(16),
        }
    )


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

        super().__init__(
            {
                "interrupt": Out(1),
                "ctlbus": In(csr.Signature(addr_width=8, data_width=32)),
                "iin": In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                "qin": In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                "iout": Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                "qout": Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                "pps": In(1),
                "sync": In(31),
                "outp": Out(32),
            }
        )

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


BUS_PROPS = Axi4LiteProperties(DATA_WIDTH=32, ADDR_WIDTH=10)


class PulserIntegration(wiring.Component):
    aclk: In(1)
    aresetn: In(1)
    interrupt: Out(1)

    s_axi_pulser: In(axi.StandardizedAxiSignature(BUS_PROPS))
    s_axis_iin: In(
        axi.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))
    )
    s_axis_qin: In(
        axi.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))
    )
    m_axis_iout: Out(
        axi.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))
    )
    m_axis_qout: Out(
        axi.StandardizedSignature(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True))
    )

    pps: In(1)
    sync: In(31)
    outp: Out(32)

    def elaborate(self, platform):
        m = Module()

        if not platform is None:
            m.domains.sync = cd_sync = ClockDomain()
            m.d.comb += [cd_sync.clk.eq(self.aclk), cd_sync.rst.eq(~self.aresetn)]

        m.submodules.pipea = pipea = axi.AxiPipelineStage(BUS_PROPS)
        m.submodules.pipeb = pipeb = axi.AxiPipelineStage(BUS_PROPS)
        axi.connect_axi(m, wiring.flipped(self.s_axi_pulser), pipea.input)
        wiring.connect(m, pipea.output, pipeb.input)

        m.submodules.converter = converter = trigger_peripheral.AXICSRBridge(addr_width=10, data_width=32)
        self.pulser_peri = m.submodules.pulser_peri = pulser_peri = PulserPeripheral(4096)

        wiring.connect(m, pipeb.output, converter.axi)
        axi.connect(m, wiring.flipped(self.s_axis_iin), pulser_peri.iin)
        axi.connect(m, wiring.flipped(self.s_axis_qin), pulser_peri.qin)
        axi.connect(m, wiring.flipped(self.m_axis_iout), pulser_peri.iout)
        axi.connect(m, wiring.flipped(self.m_axis_qout), pulser_peri.qout)
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

    class RFSoCGen3Platform(XilinxPlatform):
        device = "xczu48dr"
        package = "ffvg1517"
        speed = "2"
        resources = []
        connectors = []

    integrated_pulser = PulserIntegration()
    with open(sys.argv[1], "w") as f:
        f.write(verilog.convert(integrated_pulser, name="pulser_integraton", platform=RFSoCGen3Platform()))
    with open(sys.argv[1] + ".json", "w") as fj:
        fj.write(map_to_json(integrated_pulser.pulser_peri.ctlbus.memory_map))
