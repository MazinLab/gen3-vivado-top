from . import image_cuber, image_cuber_perhipheral, trigger, trigger_peripheral
from amaranth import *
from amaranth.lib import stream, wiring, data, enum, fifo, memory
from amaranth.lib.wiring import In, Out
from amaranth_soc.csr import Decoder
from . import axi
from .trigger import iq_stream, phase_stream, timestamp_stream
from .image_cuber_perhipheral import cuber_axi_signature

class TriggerSubsystem(wiring.Component):
    def __init__(self):
        self.cuber_peri = image_cuber_perhipheral.CuberPeri(addr_width=8, data_width=16)
        self.trig_peri = trigger_peripheral.Trigger(addr_width=12, data_width=32)
        self.trig_dma = trigger_peripheral.AXIDMA(addr_width=12, data_width=32)
        self.postage_dma = trigger_peripheral.AXIDMA(addr_width=12, data_width=32)
        self.decoder = Decoder(addr_width=16, data_width=32)
        self.converter = trigger_peripheral.AXICSRBridge(addr_width=16, data_width=32)

        super.__init__(
            {
                "s_axi_cube": In(cuber_axi_signature),
                "iq": In(iq_stream),
                "phase": In(phase_stream),
                "timestamp": In(timestamp_stream),
                "m_axi_trig": Out(self.trig_dma.dma_bus_signature),
                "m_axi_postage": Out(self.trig_dma.dma_bus_signature),
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

        decoder.add(cuber_peri.bus)
        decoder.add(trig_peri.bus)
        decoder.add(trig_dma.ctlbus)
        decoder.add(postage_dma.ctlbus)

        m.d.comb += self.int_trig_peri.eq(trig_peri.int)
        m.d.comb += self.int_cuber_peri.eq(cuber_peri.int)
        m.d.comb += self.int_dma_trig.eq(trig_dma.int)
        m.d.comb += self.int_fault_dma_trig.eq(trig_dma.fault)
        m.d.comb += self.int_dma_postage.eq(postage_dma.int)
        m.d.comb += self.int_fault_dma_postage.eq(postage_dma.fault)
        m.d.comb += self.axi_status.eq(cuber_peri.axi_status)

        m.d.comb += trig_peri.iq.eq(self.iq)
        m.d.comb += trig_peri.phase.eq(self.phase)
        m.d.comb += trig_peri.timestamp.eq(self.timestamp)

        m.d.comb += wiring.connect(m, wiring.flipped(self.s_axi_cube), cuber_peri.membus)
        m.d.comb += wiring.connect(m, trig_peri.trigger_stream, cuber_peri.trigger_stream)

        m.d.comb += wiring.connect(m, trig_dma.dmabus, self.m_axi_trig)
        m.d.comb += wiring.connect(m, postage_dma.dmabus, self.m_axi_postage)

        m.submodules.trig_fifo = trig_fifo = fifo.SyncFIFOBuffered(width = len(trig_peri.trigger_stream.payload), depth = 16)
        m.submodules.postage_fifo = postage_fifo = fifo.SyncFIFOBuffered(width = len(trig_peri.postage_stream.payload), depth = 16)

        wiring.connect(m, trig_peri.trigger_stream, trig_fifo.w_stream)
        wiring.connect(m, trig_fifo.r_stream, trig_dma.stream)

        wiring.connect(m, trig_peri.postage_stream, postage_fifo.w_stream)
        wiring.connect(m, postage_fifo.r_stream, postage_dma.stream)



        return m