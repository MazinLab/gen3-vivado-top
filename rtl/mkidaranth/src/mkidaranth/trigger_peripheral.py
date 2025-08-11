from amaranth import *

from amaranth.lib import wiring, memory, stream, data, fifo
from amaranth.lib.wiring import In, Out
from amaranth.utils import exact_log2
from amaranth_soc import csr

from . import axi

from .trigger import (
    PostageFIFO,
    TriggerState,
    PackageStreams,
    Trigger1x,
    ValvePositions,
    StreamSplitter,
    StreamValve,
    StreamArbiter,
    trigger_config,
    trigger_event,
    timestamp,
    iq,
    iq_stream,
    phase_stream,
    timestamp_stream,
    event_stream,
)

class AXICSRBridge(wiring.Component):
    def __init__(self, *, addr_width, data_width=32):
        self._dw = data_width
        self._aw = addr_width
        self._caw = addr_width - exact_log2(data_width // 8)
        self.axi_properties = axi.Axi4LiteProperties(DATA_WIDTH=data_width, ADDR_WIDTH=addr_width)
        self.csr_signature = csr.Signature(addr_width=self._caw, data_width=data_width)

        super().__init__(
            {
                "axi": In(
                    axi.Signature(
                        self.axi_properties
                    )
                ),
                "csr": Out(self.csr_signature),
            }
        )

    def elaborate(self, platform):
        m = Module()

        m.d.comb += self.csr.w_data.eq(self.axi.w.payload.data)
        m.d.comb += self.axi.r.payload.data.eq(self.csr.r_data)
        m.d.comb += self.axi.b.valid.eq(1)

        alatch = Signal(self._caw)

        with m.FSM():
            with m.State("WAITING"):
                with m.If(self.axi.aw.valid):
                    m.d.comb += self.axi.aw.ready.eq(1)
                    m.d.sync += alatch.eq(self.axi.aw.payload.addr.shift_right(self._aw - self._caw))
                    m.next = "WRITE"
                with m.ElIf(self.axi.ar.valid):
                    m.d.comb += self.axi.ar.ready.eq(1)
                    m.d.comb += self.csr.r_stb.eq(1)
                    m.d.comb += csr.addr.eq(self.axi.ar.payload.addr.shift_right(self._aw - self._caw))
                    m.next = "READ-1"
            with m.State("WRITE"):
                m.d.comb += self.csr.addr.eq(alatch)
                with m.If(self.axi.w.valid):
                    m.d.comb += self.axi.w.ready.eq(1)
                    m.d.comb += self.csr.w_stb.eq(1)
                    m.next = "WAITING"
            with m.State("READ-1"):
                m.d.sync += [
                    self.axi.r.payload.data.eq(self.csr.r_data),
                    self.axi.r.valid.eq(1)
                ]
                m.next = "READ-2"
            with m.State("READ-2"):
                with m.If(self.axi.r.valid & self.axi.r.ready):
                    m.d.sync += self.axi.r.valid.eq(0)
                    m.next = "WAITING"

        return m

class AXIDMA(wiring.Component):
    class AddressFIFO(csr.Register, access="rw"):
        def __init__(self, addr_width):
            super().__init__(
                {
                    "address": csr.Field(csr.action.W, addr_width),
                    "depth": csr.Field(csr.action.R, 8),
                    "count": csr.Field(csr.action.R, 8),
                    "lowmark": csr.Field(csr.action.RW, 8),
                }
            )

    class DMAControl(csr.Register, access="rw"):
        buffer_size: csr.Field(csr.action.RW, 24)
        flush: csr.Field(csr.action.RW, 1)

    class DebugReg(csr.Register, access="r"):
        def __init__(self, addr_width):
            super().__init__(
                {
                    "address_latch": csr.Field(csr.action.R, addr_width),
                }
            )

    def __init__(
        self,
        *,
        burst_length,
        addr_width=48,
        data_width=128,
        id_width=6,
        address_depth=8,
        ctl_data_width=64,
        debug_reg=False
    ):
        assert address_depth < 256
        assert burst_length >= 1
        self.addr_width = addr_width
        self.data_width = data_width
        self.address_depth = address_depth
        self._bpt = data_width // 8
        assert exact_log2(self._bpt) <= 0b111
        self.burst_length = burst_length
        self.debug_reg = debug_reg

        # Per the AXI4 spec bursts must not cross a 4K boundary, low key it
        # it would probably be fine in the year of our lord 2024
        assert 4096 % (burst_length * self._bpt) == 0

        regs = csr.Builder(addr_width=8, data_width=ctl_data_width)
        self._afifo = regs.add(
            "AddressFIFO", self.AddressFIFO(addr_width)
        )
        self._dmactl = regs.add("DMAControl", self.DMAControl())
        self._bridge = csr.Bridge(regs.as_memory_map())

        self.dma_bus_signature = axi.Signature(
                                    axi.Axi4Properties(
                                        READ_WRITE_MODE=axi.ReadWriteMode.WRITE_ONLY,
                                        ADDR_WIDTH=addr_width,
                                        DATA_WIDTH=data_width,
                                        ID_W_WIDTH=id_width,
                                        ID_R_WIDTH=0,
                                        WSTRB_Present=True,
                                        WLAST_Present=True,
                                        QOS_Present=False,
                                        PROT_Present=False,
                                        CACHE_Present=False,
                                        Exclusive_Accesses=False,
                                        REGION_Present=False,
                                    )
                                )

        super().__init__(
            {
                "ctlbus": In(csr.Signature(addr_width=8, data_width=ctl_data_width)),
                "dmabus": Out(self.dma_bus_signature),
                "stream": In(stream.Signature(data_width)),
                "int": Out(1),
                "fault": Out(1),
            }
        )

        self.ctlbus.memory_map = self._bridge.bus.memory_map

    def elaborate(self, platform):
        m = Module()

        m.submodules.bridge = self._bridge
        wiring.connect(m, wiring.flipped(self.ctlbus), self._bridge.bus)

        # Address FIFO <-> Bus interaction
        m.submodules.address_fifo = address_fifo = fifo.SyncFIFOBuffered(
            width=self.addr_width, depth=self.address_depth
        )
        m.d.comb += [
            address_fifo.w_data.eq(self._afifo.f.address.w_data),
            address_fifo.w_en.eq(self._afifo.f.address.w_stb),
            address_fifo.r_en.eq(0),
            self._afifo.f.depth.r_data.eq(self.address_depth),
            self._afifo.f.count.r_data.eq(address_fifo.level),
            self.int.eq(address_fifo.level < self._afifo.f.lowmark.data),
        ]

        # Basic AXI transaction manaogement
        address_latch = Signal(self.addr_width)
        m.d.comb += [
            self.dmabus.aw.payload.burst.eq(axi.BurstEncoding.INCR),
            self.dmabus.aw.payload.size.eq(exact_log2(self._bpt)),
            self.dmabus.aw.payload.len.eq(self.burst_length - 1),
            self.dmabus.b.ready.eq(1),
            self.dmabus.aw.payload.addr.eq(address_latch),
            self.dmabus.aw.payload.id.eq(0),
            self.dmabus.w.payload.data.eq(self.stream.payload),
            self.dmabus.w.payload.strb.eq(-1),
            self.dmabus.w.valid.eq(0),
            self.dmabus.w.payload.last.eq(
                ((address_latch + self._bpt) - address_fifo.r_data)
                % (self._bpt * self.burst_length)
                == 0
            ),
            self.stream.ready.eq(0),
        ]

        # Actual DMA Logic
        with m.FSM():
            with m.State("Data Wait"):
                with m.If(self.stream.valid):
                    m.next = "Address Wait"
            with m.State("Address Wait"):
                with m.If(address_fifo.r_rdy):
                    m.d.sync += address_latch.eq(address_fifo.r_data)
                    m.d.sync += self.dmabus.aw.valid.eq(1)
                    m.next = "Address Channel"
            with m.State("Address Channel"):
                with m.If(self.dmabus.aw.ready):
                    m.d.sync += self.dmabus.aw.valid.eq(0)
                    m.next = "Writing"
            with m.State("Writing"):
                m.d.comb += [
                    self.dmabus.w.valid.eq(self.stream.valid),
                    self.stream.ready.eq(self.dmabus.w.ready),
                ]
                with m.If(self.dmabus.w.valid & self.dmabus.w.ready):
                    m.d.sync += address_latch.eq(address_latch + self._bpt)
                    with m.If(
                        address_latch + self._bpt
                        == address_fifo.r_data + self._dmactl.f.buffer_size.data
                    ):
                        m.d.comb += address_fifo.r_en.eq(1)
                        with m.If(self.stream.valid):
                            m.next = "Address Wait"
                        with m.Else():
                            m.next = "Data Wait"
                    with m.Elif(
                        ((address_latch + self._bpt) - address_fifo.r_data)
                        % (self._bpt * self.burst_length)
                        == 0
                    ):
                        m.d.sync += self.dmabus.aw.valid.eq(1)
                        m.next = "Address Channel"

        with m.If(self.dmabus.b.valid & self.dmabus.b.ready):
            with m.If(self.dmabus.b.payload.resp > 1):
                m.d.sync += self.fault.eq(1)

        return m


class Trigger(wiring.Component):
    class ChunkSampler(csr.Register, access="r"):
        # These should be sampled atomically so we pack a big struct into a single field
        chunk_header: csr.Field(
            csr.action.R,
            data.StructLayout(
                {
                    "timestamp": timestamp,
                    "cycle": 52,
                    "read": 2,
                    "dropped": 1,
                    "fault": 1,
                    "empty": 1,
                }
            ),
        )

    class TriggerControl(csr.Register, access="rw"):
        prescale: csr.Field(csr.action.RW, 1)
        input_gate: csr.Field(csr.action.RW, 1)
        config: csr.Field(
            csr.action.W,
            data.StructLayout({"bin": 11, "config": trigger_config}),
        )

    class PostageControl(csr.Register, access="rw"):
        count: csr.Field(
            csr.action.RW, data.ArrayLayout(range(4 + 1), 4), init=[0, 0, 0, 0]
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

        super().__init__(
            {
                "bus": In(csr.Signature(addr_width=addr_width, data_width=data_width)),
                "iq": In(iq_stream),
                "phase": In(phase_stream),
                "timestamp": In(timestamp_stream),
                "int": Out(1),
                "trigger_events": Out(event_stream),
                "cuber_events": Out(event_stream),
                "postage_events": Out(stream.Signature(data.StructLayout({"iq": iq, "last": 1})))
            }
        )

        self.bus.memory_map = self._bridge.bus.memory_map

        # Simulation access to internal submodules
        self._postages = [None, None, None, None]
        self._triggers = [None, None, None, None]

    def elaborate(self, platform):
        m = Module()

        m.submodules.bridge = self._bridge
        wiring.connect(m, wiring.flipped(self.bus), self._bridge.bus)

        # Top Level State
        started = Signal(reset_less=True)
        cycle = Signal(52, reset_less=True)
        read = Signal(2, reset_less=True)
        drop_latch = Signal(reset_less=True)
        fault_latch = Signal(reset_less=True)
        cycle_chunk = Signal(24 + 9, reset_less=True)
        empty_latch = Signal(init=1)

        # Register Management
        cycle_chunk_scaled = Mux(
            self._trigcontrol.f.prescale.data,
            cycle_chunk.shift_right(9)[:24],
            cycle_chunk[:24],
        )
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
            m.d.sync += [
                read.eq(self._chunksampler.f.chunk_header.r_data.read),
                drop_latch.eq(0),
                cycle_chunk.eq(1),
                empty_latch.eq(1),
            ]
        with m.If(cycle_chunk != 0):
            m.d.sync += cycle_chunk.eq(cycle_chunk + 1)
        with m.If(
            ~self._trigcontrol.f.prescale.data & (cycle_chunk[:24] == 0xFFFF_FFFF_FFFF)
        ):
            m.d.sync += [cycle_chunk.eq(0), read.eq(0)]
        with m.Elif(self._trigcontrol.f.prescale.data & (cycle_chunk + 1 == 0)):
            m.d.sync += [cycle_chunk.eq(0), read.eq(0)]

        # IQ and Phase stream alignment
        m.submodules.aligner = aligner = PackageStreams()
        wiring.connect(m, wiring.flipped(self.iq), aligner.iq)
        wiring.connect(m, wiring.flipped(self.phase), aligner.phase)

        with m.If(
            ~started
            & aligner.packaged.valid
            & (aligner.packaged.payload.beat == 0b1_1111_1111)
        ):
            m.d.sync += [started.eq(1), cycle.eq(0)]
        with m.If(started):
            m.d.sync += cycle.eq(cycle + 1)
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
        m.d.comb += sr.addr.eq((cycle + 1)[:9])
        m.d.comb += cr.addr.eq((cycle + 1)[:9])
        m.d.sync += sw.addr.eq(cycle[:9])
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
        m.submodules.dma_fifo = dma_fifo = fifo.SyncFIFOBuffered(width=trigger_event.size, depth=8)
        m.submodules.cube_fifo = cube_fifo = fifo.SyncFIFOBuffered(width=trigger_event.size, depth=8)
        m.submodules.dma_valve = dma_valve = StreamValve(trigger_event, 0xDEADBEEF)
        m.submodules.cube_valve = cube_valve = StreamValve(trigger_event, 0xCAFEBEEF)

        wiring.connect(m, arb.output, split.input)
        wiring.connect(m, split.outputs[0], dma_valve.input)
        wiring.connect(m, split.outputs[1], cube_valve.input)
        wiring.connect(m, dma_valve.output, dma_fifo.w_stream)
        wiring.connect(m, cube_valve.output, cube_fifo.w_stream)
        wiring.connect(m, dma_fifo.r_stream, wiring.flipped(self.trigger_events))
        wiring.connect(m, cube_fifo.r_stream, wiring.flipped(self.cuber_events))

        m.submodules.postage_arbiter = postage_arb = StreamArbiter(data.StructLayout({"iq": iq, "last": 1}), 4*4, packet = True, credits=4)
        m.submodules.postage_valve = postage_valve = StreamValve(data.StructLayout({"iq": iq, "last": 1}), 0xDEADCAFE, True, 128)
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
            for j in range(4):
                wiring.connect(m, p.output_streams[j], postage_arb.inputs[i * 4 + j])

            m.d.comb += [
                t.input_state.eq(sr.data[i]),
                sw.data[i].eq(t.output_state),
                t.cycle.eq(cycle_chunk_scaled),
                t.config.eq(cr.data[i]),
                t.read.eq(read),
            ]

            m.d.comb += [
                t.input_stream.payload.bin.eq(Cat(C(i, unsigned(2)), cycle[:9])),
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
            self._isr.f.halfchunk.r_data.eq(cycle_chunk_scaled[-1] == 1),
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
