from amaranth import *
from amaranth.lib import wiring, fifo, stream, data
from amaranth.lib.wiring import In, Out
from amaranth_soc.csr import Decoder

from . import axi
from . import image_cuber_perhipheral, trigger_peripheral
from .trigger import iq_stream, phase_stream, timestamp, iq, trigger_event
from .image_cuber_perhipheral import cuber_axi_signature

class StreamPad(wiring.Component):
    def __init__(self, input_width, output_width):
        assert output_width >= input_width
        super().__init__(
            {
                "input": In(stream.Signature(unsigned(input_width))),
                "output": Out(stream.Signature(unsigned(output_width)))
            }
        )

    def elaborate(self, platform):
        m = Module()
        m.d.comb += [
            self.input.ready.eq(self.output.ready),
            self.output.valid.eq(self.input.valid),
            self.output.payload.eq(self.input.payload)
        ]
        return m

class StreamStripper(wiring.Component):
    def __init__(self, input_shape, output_shape, strip = lambda x: x):
        self.strip = strip
        super().__init__(
            {
                "input": In(stream.Signature(input_shape)),
                "output": Out(stream.Signature(output_shape))
            }
        )

    def elaborate(self, platform):
        m = Module()
        m.d.comb += [
            self.input.ready.eq(self.output.ready),
            self.output.valid.eq(self.input.valid),
            self.output.payload.eq(self.strip(self.input.payload))
        ]
        return m

class TriggerSubsystem(wiring.Component):
    def __init__(self):
        self.cuber_peri = image_cuber_perhipheral.CuberPeri(csr_addr_width=8, csr_data_width=32)
        self.trig_peri = trigger_peripheral.Trigger(addr_width=12, data_width=32)
        self.trig_dma = trigger_peripheral.AXIDMA(addr_width=48, data_width=64, burst_length=128, ctl_data_width=32)
        self.postage_dma = trigger_peripheral.AXIDMA(addr_width=48, data_width=32, burst_length=128, ctl_data_width=32)
        self.decoder = Decoder(addr_width=16, data_width=32)
        self.converter = trigger_peripheral.AXICSRBridge(addr_width=18, data_width=32)


        super().__init__(
            {
                "s_axi_ctrl": In(axi.StandardizedAxiSignature(self.converter.axi_properties)),
                "s_axi_cube": In(axi.StandardizedAxiSignature(cuber_axi_signature.props)),
                "s_axis_iq": In(axi.StandardizedSignature(iq_stream, data_field="payload", renames={"beat": "user"})),
                "s_axis_phase": In(axi.StandardizedSignature(phase_stream, data_field="payload", renames={"beat": "user"})),
                "timestamp": In(timestamp),
                "m_axi_trig": Out(axi.StandardizedAxiSignature(self.trig_dma.dma_bus_signature.props)),
                "m_axi_postage": Out(axi.StandardizedAxiSignature(self.postage_dma.dma_bus_signature.props)),
                "int_trig_peri": Out(1),
                "int_cuber_peri": Out(1),
                "int_dma_trig": Out(1),
                "int_fault_dma_trig": Out(1),
                "int_dma_postage": Out(1),
                "int_fault_dma_postage": Out(1),
                "axi_status": Out(1),
            }
        )
    
    def elaborate(self, platform):
        m = Module()

        m.submodules.cuber_peri = cuber_peri = self.cuber_peri
        m.submodules.trig_peri = trig_peri = self.trig_peri
        m.submodules.trig_dma = trig_dma = self.trig_dma
        m.submodules.postage_dma = postage_dma = self.postage_dma
        m.submodules.decoder = decoder = self.decoder
        m.submodules.converter = converter = self.converter

        axi.connect_axi(m, wiring.flipped(self.s_axi_ctrl), converter.axi)
        wiring.connect(m, converter.csr, decoder.bus)

        decoder.add(cuber_peri.bus)
        decoder.add(trig_peri.bus)
        decoder.add(trig_dma.ctlbus, name="Trigger")
        decoder.add(postage_dma.ctlbus, name="Postage")

        m.d.comb += self.int_trig_peri.eq(trig_peri.int)
        m.d.comb += self.int_cuber_peri.eq(cuber_peri.int)
        m.d.comb += self.int_dma_trig.eq(trig_dma.int)
        m.d.comb += self.int_fault_dma_trig.eq(trig_dma.fault)
        m.d.comb += self.int_dma_postage.eq(postage_dma.int)
        m.d.comb += self.int_fault_dma_postage.eq(postage_dma.fault)
        m.d.comb += self.axi_status.eq(cuber_peri.axi_status)

        axi.connect(m, wiring.flipped(self.s_axis_iq), trig_peri.iq)
        axi.connect(m, wiring.flipped(self.s_axis_phase), trig_peri.phase)
        m.d.comb += trig_peri.timestamp.payload.eq(self.timestamp)

        axi.connect_axi(m, wiring.flipped(self.s_axi_cube), cuber_peri.membus)
        wiring.connect(m, trig_peri.cuber_events, cuber_peri.trigger_stream)

        axi.connect_axi(m, trig_dma.dmabus, wiring.flipped(self.m_axi_trig))
        axi.connect_axi(m, postage_dma.dmabus, wiring.flipped(self.m_axi_postage))

        m.submodules.pad = pad = StreamPad(trigger_event.size, 64)
        m.submodules.strip = strip = StreamStripper(data.StructLayout({"iq": iq, "last": 1}), iq, lambda x: x.iq)
        m.submodules.trig_fifo = trig_fifo = fifo.SyncFIFOBuffered(width = trigger_event.size, depth = 16)
        m.submodules.postage_fifo = postage_fifo = fifo.SyncFIFOBuffered(width = 33, depth = 16)

        wiring.connect(m, trig_peri.trigger_events, trig_fifo.w_stream)
        wiring.connect(m, trig_fifo.r_stream, pad.input)
        wiring.connect(m, pad.output, trig_dma.stream)

        wiring.connect(m, trig_peri.postage_events, postage_fifo.w_stream)
        wiring.connect(m, postage_fifo.r_stream, strip.input)
        wiring.connect(m, strip.output, postage_dma.stream)

        return m
    
if __name__ == "__main__":
    from amaranth.back import verilog
    import sys

    integrated_trigger = TriggerSubsystem()
    with open(sys.argv[1], "w") as f:
        f.write(verilog.convert(integrated_trigger, name="trigger_subsystem"))
