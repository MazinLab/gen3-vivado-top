from amaranth import *
from amaranth.lib import wiring, stream, enum
from amaranth.lib.wiring import In, Out

class StreamPipelineStage(wiring.Component):
    def __init__(self, shape, payload_init=None):
        self.shape = shape
        self.payload_init = payload_init
        return super().__init__({
            "input": In(stream.Signature(shape, payload_init=payload_init)),
            "output": Out(stream.Signature(shape, payload_init=payload_init))
        })

    def elaborate(self, platform):
        m = Module()
        pipe_valid = Signal()
        pipe_payload = Signal(self.shape, init=self.payload_init)

        skid_valid = Signal()
        skid_payload = Signal(self.shape, init=self.payload_init)

        with m.If(self.input.ready):
            m.d.sync += [
                pipe_valid.eq(self.input.valid),
                pipe_payload.eq(self.input.payload),
            ]
            with m.If(~self.output.ready):
                m.d.sync += [
                    skid_valid.eq(pipe_valid),
                    skid_payload.eq(pipe_payload),
                ]
        with m.If(self.output.ready):
            m.d.sync += skid_valid.eq(0)

        m.d.comb += [
            self.input.ready.eq(~skid_valid),
            self.output.valid.eq(pipe_valid | skid_valid),
        ]

        with m.If(skid_valid):
            m.d.comb += self.output.payload.eq(skid_payload)
        with m.Else():
            m.d.comb += self.output.payload.eq(pipe_payload)

        return m


class ValvePositions(enum.Enum):
    OPEN = 0b00
    CLOSED = 0b01
    DUMP = 0b10
    MAGIC = 0b11


class StreamValve(wiring.Component):
    def __init__(self, shape, magic=None, packet=False, magic_packet_len=256):
        self.magic = magic
        self.magic_packet_len = magic_packet_len
        self.packet = packet
        super().__init__({
            "input": In(stream.Signature(shape)),
            "output": Out(stream.Signature(shape)),
            "turn": In(ValvePositions),
            "turning": Out(ValvePositions),
        })

    def elaborate(self, platform):
        m = Module()

        if self.packet:
            magic_packet_counter = Signal(range(self.magic_packet_len))
            platch = Signal(init=1)
            pcomplete = Signal()
            m.d.comb += pcomplete.eq(platch | (self.output.ready & self.output.valid & self.output.payload.last))
            with m.If(pcomplete):
                m.d.sync += platch.eq(1)
            with m.If(self.output.valid & self.output.ready & ~self.output.payload.last):
                m.d.sync += platch.eq(0)
                m.d.comb += pcomplete.eq(0)

        if not self.packet:
            with m.If(~self.output.valid | (self.output.valid & self.output.ready)):
                m.d.sync += self.turning.eq(self.turn)
        else:
            with m.If((~self.output.valid & pcomplete) | (self.output.valid & self.output.ready & pcomplete)):
                m.d.sync += self.turning.eq(self.turn)
            with m.If(~self.output.valid & self.turning == ValvePositions.CLOSED):
                m.d.sync += self.turning.eq(self.turn)

        with m.If(self.turning == ValvePositions.OPEN):
            m.d.comb += [
                self.output.valid.eq(self.input.valid),
                self.input.ready.eq(self.output.ready),
                self.output.payload.eq(self.input.payload),
            ]
        with m.Elif(self.turning == ValvePositions.CLOSED):
            m.d.comb += [
                self.output.valid.eq(0),
                self.input.ready.eq(0),
                self.output.payload.eq(self.input.payload),
            ]
        with m.Elif(self.turning == ValvePositions.DUMP):
            m.d.comb += [
                self.output.valid.eq(0),
                self.input.ready.eq(1),
                self.output.payload.eq(self.input.payload),
            ]
            if self.packet:
                with m.If(self.input.valid & self.input.ready & self.input.payload.last):
                    m.d.comb += pcomplete.eq(1)
                    m.d.sync += platch.eq(1)
        with m.Elif(self.turning == ValvePositions.MAGIC):
            if self.packet:
                with m.If(self.output.valid & self.output.ready):
                    m.d.sync += magic_packet_counter.eq(magic_packet_counter + 1)
                    with m.If(magic_packet_counter + 1 == self.magic_packet_len):
                        m.d.sync += magic_packet_counter.eq(0)
            m.d.comb += [
                self.output.valid.eq(1),
                self.input.ready.eq(0),
                self.output.payload.eq(
                    self.input.payload if self.magic is None else self.magic
                ),
            ]
            if self.packet:
                with m.If(magic_packet_counter + 1 == self.magic_packet_len):
                    m.d.comb += self.output.payload.last.eq(1)
                with m.Else():
                    m.d.comb += self.output.payload.last.eq(0)
        return m
