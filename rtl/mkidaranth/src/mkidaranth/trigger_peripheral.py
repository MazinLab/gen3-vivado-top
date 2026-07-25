from amaranth import *

from amaranth.lib import wiring, memory, stream, data, fifo
from amaranth.lib.wiring import In, Out
from amaranth.utils import exact_log2
from amaranth_soc import csr

from .utils import Complex
from .axi.stream import StreamPipelineStage, StreamValve, ValvePositions

from .trigger import (
    PostageFIFO,
    TriggerState,
    PackageStreams,
    Trigger1x,
    StreamSplitter,
    StreamArbiter,
    trigger_config,
    trigger_event,
    timestamp,
    iq_stream,
    phase_stream,
    timestamp_stream,
    event_stream,
)


class Trigger(wiring.Component):
    class ChunkSampler(csr.Register, access="r"):
        # TODO: These should be seperate fields
        chunk_header: csr.Field(
            csr.action.R,
            data.StructLayout({
                "timestamp": timestamp,
                "cycle": 44,
                "read": 2,
                "dropped": 1,
                "fault": 1,
                "empty": 1,
            }),
        )

    class TriggerControl(csr.Register, access="rw"):
        input_gate: csr.Field(csr.action.RW, 1)
        # TODO: This should be a different register
        config: csr.Field(
            csr.action.W,
            data.StructLayout({"bin": 11, "config": trigger_config}),
        )

    class PostageControl(csr.Register, access="rw"):
        count: csr.Field(
            csr.action.RW,
            data.ArrayLayout(range(4 + 1), 4), init=[0, 0, 0, 0]
        )
        dropped: csr.Field(csr.action.R, data.ArrayLayout(4, 4))
        fault: csr.Field(csr.action.R, data.ArrayLayout(4, 4))
        flushed: csr.Field(csr.action.R, 4)

    class InterruptStatus(csr.Register, access="r"):
        dropped: csr.Field(csr.action.R, 1)
        dropped_postage: csr.Field(csr.action.R, 1)
        fault: csr.Field(csr.action.R, 1)
        fault_postage: csr.Field(csr.action.R, 1)
        halfchunk: csr.Field(csr.action.R, 1)
        fullchunk: csr.Field(csr.action.R, 1)

    class InterruptEnable(csr.Register, access="rw"):
        dropped: csr.Field(csr.action.RW, 1)
        dropped_postage: csr.Field(csr.action.RW, 1)
        fault: csr.Field(csr.action.RW, 1)
        fault_postage: csr.Field(csr.action.RW, 1)
        halfchunk: csr.Field(csr.action.RW, 1)
        fullchunk: csr.Field(csr.action.RW, 1)

    class ValveControl(csr.Register, access="rw"):
        trigger: csr.Field(csr.action.RW, ValvePositions)
        cuber: csr.Field(csr.action.RW, ValvePositions)
        stamper: csr.Field(csr.action.RW, ValvePositions)

    class ValveStatus(csr.Register, access="r"):
        trigger: csr.Field(csr.action.R, ValvePositions)
        cuber: csr.Field(csr.action.R, ValvePositions)
        stamper: csr.Field(csr.action.R, ValvePositions)

    def __init__(self, *, addr_width, data_width):
        regs = csr.Builder(addr_width=addr_width, data_width=data_width)
        self._chunksampler = regs.add("ChunkSampler", self.ChunkSampler())
        self._trigcontrol = regs.add("TriggerControl", self.TriggerControl())
        self._postcontrol = regs.add("PostageControl", self.PostageControl())
        self._valvecontrol = regs.add("ValveControl", self.ValveControl())
        self._valvestatus = regs.add("ValveStatus", self.ValveStatus())
        self._isr = regs.add("InterruptStatus", self.InterruptStatus())
        self._ier = regs.add("InterruptEnable", self.InterruptEnable())
        self._bridge = csr.Bridge(regs.as_memory_map())

        super().__init__({
            "bus": In(csr.Signature(addr_width=addr_width, data_width=data_width)),
            "iq": In(iq_stream),
            "phase": In(phase_stream),
            "timestamp": In(timestamp_stream),
            "int": Out(1),
            "trigger_events": Out(event_stream),
            "cuber_events": Out(event_stream),
            "postage_events": Out(stream.Signature(data.StructLayout({"iq": Complex(16), "last": 1})))
        })

        self.bus.memory_map = self._bridge.bus.memory_map

        # Simulation access to internal submodules
        self._postages = [None, None, None, None]
        self._triggers = [None, None, None, None]

    def elaborate(self, platform):
        m = Module()

        m.submodules.bridge = self._bridge
        wiring.connect(m, wiring.flipped(self.bus), self._bridge.bus)

        # IQ and Phase stream alignment
        m.submodules.aligner = aligner = PackageStreams()
        wiring.connect(m, wiring.flipped(self.iq), aligner.iq)
        wiring.connect(m, wiring.flipped(self.phase), aligner.phase)

        # Top Level State
        started = Signal(reset_less=True)
        read = Signal(2, reset_less=True)
        drop_latch = Signal(reset_less=True)
        fault_latch = Signal(reset_less=True)
        empty_latch = Signal(init=1)
        cycle = Signal(44)
        cycle_chunk = Signal(24)
        beat = aligner.packaged.payload.beat

        # Register Management
        m.d.comb += [
            self._chunksampler.f.chunk_header.r_data.cycle.eq(cycle),
            self._chunksampler.f.chunk_header.r_data.timestamp.eq(
                self.timestamp.payload
            ),
            self._chunksampler.f.chunk_header.r_data.read.eq(
                Mux(read == 3, 1, read + 1)
            ),
            self._chunksampler.f.chunk_header.r_data.dropped.eq(drop_latch),
            self._chunksampler.f.chunk_header.r_data.empty.eq(empty_latch),
        ]
        with m.If(self._chunksampler.f.chunk_header.r_stb):
            m.d.sync += drop_latch.eq(0)
            m.d.sync += empty_latch.eq(1)
            m.d.sync += read.eq(Mux(read == 3, 1, read + 1))
            m.d.sync += cycle_chunk.eq(0)
            with m.If(aligner.packaged.valid & (beat == 0b1_1111_1111)):
                m.d.sync += cycle_chunk.eq(1)

        with m.If(
            ~started
            & aligner.packaged.valid
            & (aligner.packaged.payload.beat == 0b1_1111_1111)
        ):
            m.d.sync += [started.eq(1), cycle.eq(0), cycle_chunk.eq(0)]
        with m.Elif(aligner.packaged.valid & (beat == 0b1_1111_1111)):
            m.d.sync += cycle.eq(cycle + 1)
            m.d.sync += cycle_chunk.eq(cycle_chunk + 1)
            with m.If((cycle_chunk + 1) & 0xff_ffff == 0):
                m.d.sync += read.eq(0)

        m.d.comb += self._chunksampler.f.chunk_header.r_data.fault.eq(
            aligner.fault | fault_latch
        )

        # Trigger state and configuration
        m.submodules.state_memory = state_memory = memory.Memory(
            shape=data.ArrayLayout(TriggerState, 4), depth=2048, init=[]
        )
        m.submodules.config_memory = config_memory = memory.Memory(
            shape=data.ArrayLayout(trigger_config, 4), depth=2048, init=[]
        )

        sr = state_memory.read_port(domain="sync")
        cr = config_memory.read_port(domain="sync")
        sw = state_memory.write_port()
        cw = config_memory.write_port(granularity=1)

        # Address generation logic...
        m.d.comb += sr.addr.eq((beat + 2)[:9])
        m.d.comb += cr.addr.eq((beat + 2)[:9])
        m.d.sync += sw.addr.eq(beat[:9])
        m.d.sync += cw.addr.eq(self._trigcontrol.f.config.w_data.bin[2:])
        m.d.sync += sw.en.eq(started)
        m.d.sync += cw.en.eq(
            self._trigcontrol.f.config.w_stb
            << self._trigcontrol.f.config.w_data.bin[:2]
        )
        m.d.sync += cw.data.eq(
            self._trigcontrol.f.config.w_data.config.as_value().replicate(4)
        )

        m.submodules.arbiter = arb = StreamArbiter(trigger_event, 4, credits = 2)
        m.submodules.splitter = split = StreamSplitter(trigger_event, 2)
        m.submodules.cube_fifo = cube_fifo = fifo.SyncFIFOBuffered(width=trigger_event.size, depth=8)
        m.submodules.dma_valve = dma_valve = StreamValve(trigger_event, 0xDEADBEEF)
        m.submodules.cube_valve = cube_valve = StreamValve(trigger_event, 0xCAFEBEEF)

        m.submodules.arbiter_pipeline = arb_pipe = StreamPipelineStage(trigger_event)
        m.submodules.dma_pipeline = dma_pipe = StreamPipelineStage(trigger_event)
        m.submodules.cube_pipeline = cube_pipe = StreamPipelineStage(trigger_event)

        wiring.connect(m, arb.output, arb_pipe.input)
        wiring.connect(m, arb_pipe.output, split.input)
        wiring.connect(m, split.outputs[0], dma_pipe.input)
        wiring.connect(m, split.outputs[1], cube_pipe.input)
        wiring.connect(m, dma_pipe.output, dma_valve.input)
        wiring.connect(m, cube_pipe.output, cube_valve.input)
        wiring.connect(m, cube_valve.output, cube_fifo.w_stream)
        wiring.connect(m, dma_valve.output, wiring.flipped(self.trigger_events))
        wiring.connect(m, cube_fifo.r_stream, wiring.flipped(self.cuber_events))

        m.submodules.postage_arbiter = postage_arb = StreamArbiter(data.StructLayout({"iq": Complex(16), "last": 1}), 4, packet=True, credits=2)
        m.submodules.postage_valve = postage_valve = StreamValve(data.StructLayout({"iq": Complex(16), "last": 1}), 0xDEADCAFE, True, 128)
        wiring.connect(m, postage_arb.output, postage_valve.input)
        wiring.connect(m, postage_valve.output, wiring.flipped(self.postage_events))

        m.d.comb += [
            dma_valve.turn.eq(self._valvecontrol.f.trigger.data),
            cube_valve.turn.eq(self._valvecontrol.f.cuber.data),
            postage_valve.turn.eq(self._valvecontrol.f.stamper.data),
            self._valvestatus.f.trigger.r_data.eq(dma_valve.turning),
            self._valvestatus.f.cuber.r_data.eq(cube_valve.turning),
            self._valvestatus.f.stamper.r_data.eq(postage_valve.turning)
        ]

        # Trigger instantiation, 1 for each lane
        triggers = []
        for i in range(4):
            self._triggers[i] = m.submodules[f"trigger{i}"] = t = Trigger1x()
            self._postages[i] = m.submodules[f"postage{i}"] = p = PostageFIFO(8, 128, 4)
            wiring.connect(m, t.postage_stream, p.postage_stream)
            triggers.append(t)

            m.submodules[f"event_fifo{i}"] = ef = fifo.SyncFIFOBuffered(width=trigger_event.size, depth=8)
            wiring.connect(m, t.event_stream, ef.w_stream)
            wiring.connect(m, ef.r_stream, arb.inputs[i])

            m.submodules[f"postage_arb{i}"] = a = StreamArbiter(data.StructLayout({"iq": Complex(16), "last": 1}), 4, packet=True, credits=2)
            m.submodules[f"postage_arbpipe{i}"] = apipe = StreamPipelineStage(data.StructLayout({"iq": Complex(16), "last": 1}))
            for j in range(4):
                wiring.connect(m, p.output_streams[j], a.inputs[j])
            wiring.connect(m, a.output, apipe.input)
            wiring.connect(m, apipe.output, postage_arb.inputs[i])

            m.d.sync += [
                t.input_state.eq(sr.data[i]),
                t.config.eq(cr.data[i]),
            ]

            m.d.comb += [
                sw.data[i].eq(t.output_state),
                t.cycle.eq(cycle_chunk),
                t.read.eq(read),
            ]

            m.d.comb += [
                t.input_stream.payload.bin.eq(Cat(C(i, unsigned(2)), beat[:9])),
                t.input_stream.payload.iq.eq(aligner.packaged.payload.iq[i]),
                t.input_stream.payload.phase.eq(aligner.packaged.payload.phase[i]),
                t.input_stream.valid.eq(
                    started
                    & aligner.packaged.valid
                    & (~self._trigcontrol.f.input_gate.data)
                ),
            ]

            m.d.comb += [
                p.count.eq(self._postcontrol.f.count.data[i]),
                p.cleardropped.eq(self._postcontrol.f.dropped.r_stb),
                self._postcontrol.f.dropped.r_data[i].eq(p.dropped),
                self._postcontrol.f.fault.r_data[i].eq(p.fault),
                self._postcontrol.f.flushed.r_data[i].eq(p.flushed),
            ]

            with m.If(t.dropped):
                m.d.sync += drop_latch.eq(1)
            with m.If(p.fault != 0):
                m.d.sync += fault_latch.eq(1)

            with m.If(
                t.event_stream.valid
                & t.event_stream.ready
                & (t.event_stream.payload.read == read)
            ):
                m.d.sync += empty_latch.eq(0)

            with m.If(self._chunksampler.f.chunk_header.r_stb):
                with m.If(
                    (
                        self._chunksampler.f.chunk_header.r_data.read
                        == t.event_stream.payload.read
                    )
                    & t.event_stream.valid
                    & ~t.event_stream.ready
                ):
                    m.d.sync += fault_latch.eq(1)

        # Interrupt Control
        m.d.comb += [
            self._isr.f.dropped.r_data.eq(drop_latch),
            self._isr.f.dropped_postage.r_data.eq(
                self._postcontrol.f.dropped.r_data.as_value().any()
            ),
            self._isr.f.fault.r_data.eq(drop_latch),
            self._isr.f.fault_postage.r_data.eq(
                self._postcontrol.f.fault.r_data.as_value().any()
            ),
            self._isr.f.halfchunk.r_data.eq(cycle_chunk[-1] == 1),
            self._isr.f.fullchunk.r_data.eq((read == 0) & started),
        ]

        m.d.sync += self.int.eq(
            (self._isr.f.dropped.r_data & self._ier.f.dropped.data)
            | (self._isr.f.dropped_postage.r_data & self._ier.f.dropped_postage.data)
            | (self._isr.f.fault.r_data & self._ier.f.fault.data)
            | (self._isr.f.fault_postage.r_data & self._ier.f.fault_postage.data)
            | (self._isr.f.halfchunk.r_data & self._ier.f.halfchunk.data)
            | (self._isr.f.fullchunk.r_data & self._ier.f.fullchunk.data)
        )

        return m
