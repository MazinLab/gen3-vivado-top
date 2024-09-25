from amaranth import *
from amaranth.lib import stream, wiring, data, enum, fifo
from amaranth.lib.wiring import In, Out


trigger_config = data.StructLayout(
    {
        "threshold": signed(16),
        "holdoff": 8,
        "postage": 1,
    }
)


class TriggerState(data.Struct):
    class State(enum.Enum):
        RESET = 0
        WAITING = 1
        TRIGGERED = 2
        HOLDING = 3

    state: State
    info: data.UnionLayout(
        {
            "waiting": data.StructLayout({"maxseen": signed(16)}),
            "triggered": data.StructLayout({"minseen": signed(16)}),
            "holding": data.StructLayout({"holdoff": signed(16)}),
        }
    )


trigger_event = data.StructLayout(
    {
        "phase": signed(16),
        "cycle": 24,
        "bin": 11,
        "read": 2,
    }
)

iq = data.StructLayout(
    {
        "real": signed(16),
        "imag": signed(16),
    }
)

timestamp = data.StructLayout(
    {
        "secs": 32,
        "ns": 32,
        "subns": 8,
    }
)

packaged = data.StructLayout(
    {
        "beat": 9,
        "iq": data.ArrayLayout(iq, 4),
        "phase": data.ArrayLayout(signed(16), 4),
    }
)

postage_event = data.StructLayout(
    {
        "iq": iq,
        "cycle": 24,
        "bin": 11,
        "read": 2,
        "triggered": 1,
    }
)

trigger_input = data.StructLayout({"bin": 11, "iq": iq, "phase": signed(16)})

iq_stream = stream.Signature(data.StructLayout({"beat": 8, "payload": data.ArrayLayout(iq, 8)}))
phase_stream = stream.Signature(data.StructLayout({"beat": 9, "payload": data.ArrayLayout(signed(16), 4)}))
timestamp_stream = stream.Signature(timestamp, always_ready=True, always_valid=True)

packaged_stream = stream.Signature(packaged, always_ready=True)
postage_stream = stream.Signature(postage_event, always_ready=True)

trigger_stream = stream.Signature(trigger_input, always_ready=True)
event_stream = stream.Signature(trigger_event)


class PackageStreams(wiring.Component):
    iq: In(iq_stream)
    phase: In(phase_stream)

    packaged: Out(packaged_stream)
    fault: Out(1)

    def elaborate(self, platform):
        m = Module()

        started = Signal()
        iq_latch = Signal(data.ArrayLayout(iq, 4), reset_less=True)
        iq_this = Signal(data.ArrayLayout(iq, 4))

        fault_sticky = Signal(reset_less=True)

        m.d.comb += self.fault.eq(fault_sticky)

        m.d.comb += [
            self.iq.ready.eq(started | (self.iq.valid & self.phase.valid)),
            self.phase.ready.eq(started | (self.iq.valid & self.phase.valid)),
        ]

        with m.If(~started):
            m.d.sync += started.eq(self.iq.valid & self.phase.valid)
        with m.If(self.iq.valid):
            m.d.comb += self.fault.eq(
                fault_sticky
                | ~(
                    (self.iq.payload.beat == self.phase.payload.beat >> 1)
                    & (self.phase.payload.beat[0] == 0)
                    & (self.phase.valid | ~started)
                )
            )
            m.d.sync += iq_latch.eq(self.iq.payload.payload[4:])
            m.d.comb += iq_this.eq(self.iq.payload.payload[:4])
        with m.Else():
            m.d.comb += iq_this.eq(iq_latch)

        m.d.comb += [
            self.packaged.payload.beat.eq(self.phase.payload.beat),
            self.packaged.payload.iq.eq(iq_this),
            self.packaged.payload.phase.eq(self.phase.payload.payload),
            self.packaged.valid.eq(started | (self.iq.valid & self.phase.valid)),
        ]

        m.d.sync += fault_sticky.eq(self.fault | fault_sticky)

        return m


class Trigger1x(wiring.Component):
    config: In(trigger_config)

    input_state: In(TriggerState)
    output_state: Out(TriggerState)

    input_stream: In(trigger_stream)
    event_stream: Out(event_stream)
    postage_stream: Out(postage_stream)

    cycle: In(24)
    read: In(2)

    dropped: Out(1)

    def elaborate(self, platform):
        m = Module()
        m.d.sync += self.event_stream.valid.eq(
            Mux(
                self.event_stream.ready & self.event_stream.valid,
                0,
                self.event_stream.valid,
            )
        )
        m.d.sync += self.dropped.eq(0)
        m.d.sync += [self.output_state.eq(self.input_state)]

        m.d.sync += [
            self.postage_stream.payload.bin.eq(self.input_stream.payload.bin),
            self.postage_stream.payload.iq.eq(self.input_stream.payload.iq),
            self.postage_stream.payload.cycle.eq(self.cycle),
            self.postage_stream.payload.read.eq(self.read),
            self.postage_stream.payload.triggered.eq(0),
        ]
        m.d.sync += self.postage_stream.valid.eq(0)
        with m.If(self.config.postage):
            m.d.sync += self.postage_stream.valid.eq(1)

        with m.Switch(self.input_state.state):
            with m.Case(TriggerState.State.RESET):
                m.d.sync += [
                    self.output_state.state.eq(TriggerState.State.WAITING),
                    self.output_state.info.waiting.maxseen.eq(-(1 << 15)),
                ]
            with m.Case(TriggerState.State.WAITING):
                with m.If(self.input_state.info.waiting.maxseen <= self.config.threshold):
                    m.d.sync += [
                        self.output_state.state.eq(TriggerState.State.WAITING),
                        self.output_state.info.waiting.maxseen.eq(
                            Mux(
                                self.output_state.info.waiting.maxseen > self.input_stream.payload.phase,
                                self.output_state.info.waiting.maxseen,
                                self.input_stream.payload.phase,
                            )
                        ),
                    ]
                with m.Elif(self.input_stream.payload.phase < self.config.threshold):
                    m.d.sync += [
                        self.output_state.state.eq(TriggerState.State.TRIGGERED),
                        self.output_state.info.triggered.minseen.eq(self.input_stream.payload.phase),
                    ]
                with m.Else():
                    m.d.sync += self.output_state.info.waiting.maxseen.eq(
                        Mux(
                            self.output_state.info.waiting.maxseen > self.input_stream.payload.phase,
                            self.output_state.info.waiting.maxseen,
                            self.input_stream.payload.phase,
                        )
                    )
            with m.Case(TriggerState.State.TRIGGERED):
                with m.If(self.input_state.info.triggered.minseen >= self.input_stream.payload.phase):
                    m.d.sync += self.output_state.info.triggered.minseen.eq(self.input_stream.payload.phase)
                with m.Else():
                    m.d.sync += [
                        self.output_state.state.eq(TriggerState.State.HOLDING),
                        self.output_state.info.holding.holdoff.eq(self.config.holdoff),
                    ]

                    with m.If(~self.event_stream.valid | self.event_stream.ready):
                        m.d.sync += [
                            self.event_stream.payload.phase.eq(self.input_state.info.triggered.minseen),
                            self.event_stream.payload.bin.eq(self.input_stream.payload.bin),
                            self.event_stream.payload.cycle.eq(self.cycle),
                            self.event_stream.payload.read.eq(self.read),
                            self.event_stream.valid.eq(1),
                            self.postage_stream.payload.triggered.eq(1),
                        ]
                    with m.Else():
                        m.d.sync += self.dropped.eq(1)
            with m.Case(TriggerState.State.HOLDING):
                with m.If(self.input_state.info.holding.holdoff == 0):
                    m.d.sync += [
                        self.output_state.state.eq(TriggerState.State.WAITING),
                        self.output_state.info.waiting.maxseen.eq(self.input_stream.payload.phase),
                    ]
                with m.Else():
                    m.d.sync += self.output_state.info.holding.holdoff.eq(
                        self.input_state.info.holding.holdoff - 1
                    )
        with m.If(~self.input_stream.valid):
            m.d.sync += self.output_state.state.eq(TriggerState.State.RESET)
        return m


class PostageFIFO(wiring.Component):
    def __init__(self, before, length, count):
        self._before = before
        self._length = length
        self._count = count
        super().__init__(
            {
                "postage_stream": In(postage_stream),
                "output_streams": Out(stream.Signature(data.StructLayout({"iq": iq, "last": 1}))).array(
                    count
                ),
                "output_metadata": Out(
                    data.ArrayLayout(data.StructLayout({"bin": 11, "cycle": 24, "read": 2}), count)
                ),
                "count": In(range(count + 1)),
                "flushed": Out(1),
                "dropped": Out(count),
                "fault": Out(count),
            }
        )

    def elaborate(self, platform):
        m = Module()

        started = Signal(reset_less=True)

        # Trigger to all active state machines to write out their buffers and stop
        flush = Signal(reset_less=True)
        # Responses from all active state machines
        flushed = Signal(self._count, reset_less=True)

        # Internally copy the count so that we can flush properly
        count = Signal(range(self._count + 1), reset_less=True)

        # Counts up for each lane we get postage from wrapping at the internal count
        lane_counter = Signal(range(self._count), reset_less=True)
        with m.If(started & self.postage_stream.valid):
            m.d.sync += lane_counter.eq(Mux(lane_counter + 1 == count, 0, lane_counter + 1))

        # When started explicitly reset the required state
        with m.If((count == 0) & (self.count > 0)):
            m.d.sync += [
                count.eq(self.count),
                flush.eq(0),
                self.flushed.eq(0),
                flushed.eq(0),
                self.dropped.eq(0),
                started.eq(1),
                self.fault.eq(0),
                lane_counter.eq(0),
            ]
        with m.If((count != 0) & (self.count == 0)):
            m.d.sync += flush.eq(1)
            # When told to stop don't stop or report flushed until all active state machines
            # finish writing data to the postage writer
            with m.If(flushed == (1 << count) - 1):
                m.d.sync += [
                    started.eq(0),
                    count.eq(0),
                    self.flushed.eq(1),
                ]

        buffer_fifos = []
        storage_fifos = []
        for i in range(self._count):
            fb = fifo.SyncFIFOBuffered(width=32, depth=self._before + 1)
            fbws = fb.w_stream
            fbrs = fb.r_stream

            fs = fifo.SyncFIFOBuffered(width=32, depth=self._length)
            fsws = fs.w_stream
            fsrs = fs.r_stream

            buffer_fifos.append((fb, fbws, fbrs))
            storage_fifos.append((fs, fsws, fsrs))
            m.submodules[f"buffer_fifo{i}"] = fb
            m.submodules[f"storage_fifo{i}"] = fs

            leadin_counter = Signal(range(self._before + 1), reset_less=True)
            leadin_point = self._before

            with m.If(self.postage_stream.valid & (lane_counter == i) & (leadin_counter != leadin_point)):
                m.d.sync += leadin_counter.eq(leadin_counter + 1)

            m.d.sync += [
                fbws.payload.eq(self.postage_stream.payload.iq),
                fbws.valid.eq(self.postage_stream.valid & (lane_counter == i)),
                fbrs.ready.eq(
                    self.postage_stream.valid & (lane_counter == i) & (leadin_counter == leadin_point)
                ),
                fsws.payload.eq(fbrs.payload),
            ]

            written = Signal(range(self._length + 1), reset_less=True)
            written_internal = Signal(range(self._length), reset_less=True)

            with m.FSM(name=f"fsmchannel{i}") as f:
                with m.State("waiting"):
                    with m.If(self.postage_stream.valid & (lane_counter == i)):
                        m.d.sync += [written_internal.eq(0), written.eq(0)]
                        with m.If(fsrs.valid):
                            m.next = "flushing"
                        with m.If(flush):
                            m.d.sync += flushed[i].eq(1)
                        with m.If(
                            self.postage_stream.payload.triggered & (leadin_counter == leadin_point) & ~flush
                        ):
                            with m.If(fsws.ready):
                                m.d.sync += fsws.valid.eq(1)
                                m.d.sync += [
                                    self.output_metadata[i].bin.eq(self.postage_stream.payload.bin),
                                    self.output_metadata[i].cycle.eq(self.postage_stream.payload.cycle),
                                    self.output_metadata[i].read.eq(self.postage_stream.payload.read),
                                    written_internal.eq(written_internal + 1),
                                ]
                                with m.If(~fsws.ready):
                                    m.d.sync += [self.dropped[i].eq(1), self.fault[i].eq(1)]
                                    m.next = "flushing"
                                with m.Else():
                                    m.next = "triggered"

                with m.State("triggered"):
                    with m.If(self.postage_stream.valid & (lane_counter == i)):
                        m.d.sync += [
                            fsws.valid.eq(1),
                            written_internal.eq(written_internal + 1),
                        ]
                        with m.If(written_internal + 1 == self._length):
                            m.next = "writing"
                        with m.Elif(~fsws.ready):
                            m.d.sync += [self.fault[i].eq(1)]
                            m.next = "flushing"
                    with m.Else():
                        m.d.sync += fsws.valid.eq(0)

                with m.State("writing"):
                    m.d.sync += fsws.valid.eq(0)
                    with m.If(written == self._length):
                        with m.If(flush):
                            m.d.sync += flushed[i].eq(1)
                        m.next = "waiting"

                with m.State("flushing"):
                    m.d.sync += fsws.valid.eq(0)
                    with m.If(fs.level == 0 & ~fsrs.valid):
                        with m.If(flush):
                            m.d.sync += flushed[i].eq(1)
                        m.next = "waiting"

            with m.If(self.postage_stream.valid & (lane_counter == i)):
                with m.If(
                    self.postage_stream.payload.triggered
                    & ~(f.ongoing("waiting") | f.ongoing("triggered"))
                    & ~flush
                ):
                    m.d.sync += self.dropped[i].eq(1)
                with m.If((leadin_counter == leadin_point) & ~fbrs.valid):
                    m.d.sync += self.fault[i].eq(1)
                with m.If(~fbws.ready):
                    m.d.sync += self.fault[i].eq(1)

            m.d.comb += [
                fsrs.ready.eq(
                    f.ongoing("flushing")
                    | self.output_streams[i].ready & (f.ongoing("triggered") | f.ongoing("writing"))
                ),
                self.output_streams[i].valid.eq(fsrs.valid & (f.ongoing("triggered") | f.ongoing("writing"))),
                self.output_streams[i].payload.iq.eq(fsrs.payload),
                self.output_streams[i].payload.last.eq(written + 1 == self._length),
            ]

            with m.If(fsrs.ready & self.output_streams[i].valid):
                m.d.sync += written.eq(written + 1)

            with m.If(~started):
                m.d.sync += leadin_counter.eq(0)
                m.d.sync += fbrs.ready.eq(1)
                m.d.sync += fbws.valid.eq(0)
        return m
