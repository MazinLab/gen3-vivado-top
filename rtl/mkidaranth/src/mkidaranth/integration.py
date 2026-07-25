from amaranth import *
from amaranth.build.dsl import Attrs
from amaranth.lib import data, fifo, stream, wiring
from amaranth.lib.wiring import In, Out
from amaranth_soc.csr import Decoder

from . import image_cuber_perhipheral, trigger_peripheral
from .axi import bus, ip
from .axi.stream import StreamPipelineStage
from .utils import Complex

from .image_cuber_perhipheral import cuber_axi_signature
from .trigger import iq_stream, phase_stream, timestamp, trigger_event


class StreamPad(wiring.Component):
    def __init__(self, input_width, output_width):
        assert output_width >= input_width
        super().__init__({
            "input": In(stream.Signature(unsigned(input_width))),
            "output": Out(stream.Signature(unsigned(output_width))),
        })

    def elaborate(self, platform):
        m = Module()
        m.d.comb += [
            self.input.ready.eq(self.output.ready),
            self.output.valid.eq(self.input.valid),
            self.output.payload.eq(self.input.payload),
        ]
        return m


class StreamStripper(wiring.Component):
    def __init__(self, input_shape, output_shape, strip=lambda x: x):
        self.strip = strip
        super().__init__({
            "input": In(stream.Signature(input_shape)),
            "output": Out(stream.Signature(output_shape))
        })

    def elaborate(self, platform):
        m = Module()
        m.d.comb += [
            self.input.ready.eq(self.output.ready),
            self.output.valid.eq(self.input.valid),
            self.output.payload.eq(self.strip(self.input.payload)),
        ]
        return m


class TriggerSubsystem(wiring.Component):
    def __init__(self, enable_cuber=True, sim_clocks=False):
        self.enable_cuber = enable_cuber
        self.sim_clocks = sim_clocks
        if self.enable_cuber:
            self.cuber_peri = image_cuber_perhipheral.CuberPeri(csr_addr_width=8, csr_data_width=32)
        self.trig_peri = trigger_peripheral.Trigger(addr_width=12, data_width=32)
        self.trig_dma = ip.AXIDMA(
            addr_width=48, data_width=64, burst_length=128, input_fifo=256, ctl_data_width=32
        )
        self.postage_dma = ip.AXIDMA(
            addr_width=48, data_width=32, burst_length=128, input_fifo=256, ctl_data_width=32
        )
        self.decoder = Decoder(addr_width=16, data_width=32)
        self.converter = ip.AXICSRBridge(addr_width=18, data_width=32)

        self.decoder.add(self.trig_peri.bus, name="Trigger")
        self.decoder.add(self.trig_dma.ctlbus, name="TriggerDMA")
        self.decoder.add(self.postage_dma.ctlbus, name="PostageDMA")
        if self.enable_cuber:
            self.decoder_slow = Decoder(addr_width=16, data_width=32)
            self.converter_slow = ip.AXICSRBridge(addr_width=18, data_width=32)
            self.decoder_slow.add(self.cuber_peri.bus, name="CuberDMA")

        super().__init__({
            "aclk": In(1),
            "aresetn": In(1),
            "s_axi_ctrl_slow_aclk": In(1),
            "s_axi_ctrl_slow_aresetn": In(1),
            "s_axi_cube_aclk": In(1),
            "s_axi_cube_aresetn": In(1),
            "s_axi_ctrl": In(bus.StandardizedAxiSignature(self.converter.axi_properties)),
            "s_axi_ctrl_slow": In(bus.StandardizedAxiSignature(self.converter.axi_properties)),
            "s_axi_cube": In(bus.StandardizedAxiSignature(cuber_axi_signature.props)),
            "s_axis_iq": In(bus.StandardizedSignature(iq_stream, data_field="payload", renames={"beat": "user"})),
            "s_axis_phase": In(bus.StandardizedSignature(phase_stream, data_field="payload", renames={"beat": "user"})),
            "timestamp": In(timestamp),
            "m_axi_trig": Out(bus.StandardizedAxiSignature(self.trig_dma.dma_bus_signature.props)),
            "m_axi_postage": Out(bus.StandardizedAxiSignature(self.postage_dma.dma_bus_signature.props)),
            "int_trig_peri": Out(1),
            "int_cuber_peri": Out(1),
            "int_dma_trig": Out(1),
            "int_fault_dma_trig": Out(1),
            "int_dma_postage": Out(1),
            "int_fault_dma_postage": Out(1),
        })

    def elaborate(self, platform):
        m = Module()

        self.s_axi_ctrl_slow_aclk._attrs = Attrs(
            X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 s_axi_ctrl_slow_aclk CLK",
            X_INTERFACE_PARAMETER="ASSOCIATED_BUSIF s_axi_ctrl_slow, ASSOCIATED_RESET s_axi_ctrl_slow_aresetn, FREQ_HZ 256000000",
        )
        self.s_axi_cube_aclk._attrs = Attrs(
            X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 s_axi_cube_aclk CLK",
            X_INTERFACE_PARAMETER="ASSOCIATED_BUSIF s_axi_cube, ASSOCIATED_RESET s_axi_cube_aresetn, FREQ_HZ 256000000",
        )

        if not self.sim_clocks:
            m.domains.sync = cd_sync = ClockDomain()
            m.d.comb += [cd_sync.clk.eq(self.aclk), cd_sync.rst.eq(~self.aresetn)]
            m.domains.slow = cd_slow = ClockDomain()
            m.d.comb += [
                cd_slow.clk.eq(self.s_axi_ctrl_slow_aclk),
                cd_slow.rst.eq(~self.s_axi_ctrl_slow_aresetn),
            ]

        m.submodules.trig_peri = trig_peri = self.trig_peri
        m.submodules.trig_dma = trig_dma = self.trig_dma
        m.submodules.postage_dma = postage_dma = self.postage_dma
        m.submodules.decoder = decoder = self.decoder
        m.submodules.converter = converter = self.converter

        bus.connect_axi(m, wiring.flipped(self.s_axi_ctrl), converter.axi)
        wiring.connect(m, converter.csr, decoder.bus)

        m.d.comb += self.int_trig_peri.eq(trig_peri.int)
        m.d.comb += self.int_dma_trig.eq(trig_dma.int)
        m.d.comb += self.int_fault_dma_trig.eq(trig_dma.fault)
        m.d.comb += self.int_dma_postage.eq(postage_dma.int)
        m.d.comb += self.int_fault_dma_postage.eq(postage_dma.fault)

        bus.connect(m, wiring.flipped(self.s_axis_iq), trig_peri.iq)
        bus.connect(m, wiring.flipped(self.s_axis_phase), trig_peri.phase)
        m.d.comb += trig_peri.timestamp.payload.eq(self.timestamp)

        if self.enable_cuber:
            m.submodules.decoder_slow = decoder_slow = DomainRenamer("slow")(self.decoder_slow)
            m.submodules.converter_slow = converter_slow = DomainRenamer("slow")(self.converter_slow)
            m.submodules.cuber_peri = cuber_peri = DomainRenamer("slow")(self.cuber_peri)
            m.submodules.cuber_axi_pipe = cuber_axi_pipe = DomainRenamer("slow")(
                bus.AxiPipelineStage(cuber_axi_signature.props)
            )

            bus.connect_axi(m, wiring.flipped(self.s_axi_ctrl_slow), converter_slow.axi)
            wiring.connect(m, converter_slow.csr, decoder_slow.bus)
            bus.connect_axi(m, wiring.flipped(self.s_axi_cube), cuber_axi_pipe.input)
            wiring.connect(m, cuber_axi_pipe.output, cuber_peri.membus)

            m.submodules.fifo_input_pipeline = fi = StreamPipelineStage(
                trig_peri.cuber_events.payload.shape()
            )
            m.submodules.fifo_output_pipeline = fo = DomainRenamer("slow")(
                StreamPipelineStage(trig_peri.cuber_events.payload.shape())
            )
            m.submodules.cdc_fifo = cdc_fifo = fifo.AsyncFIFOBuffered(
                width=trig_peri.cuber_events.payload.shape().size, depth=256, w_domain="sync", r_domain="slow"
            )
            wiring.connect(m, trig_peri.cuber_events, fi.input)
            wiring.connect(m, fi.output, cdc_fifo.w_stream)
            wiring.connect(m, cdc_fifo.r_stream, fo.input)
            wiring.connect(m, fo.output, cuber_peri.trigger_stream)
            m.d.comb += self.int_cuber_peri.eq(cuber_peri.int)
        else:
            m.d.comb += trig_peri.cuber_events.ready.eq(1)

        m.submodules.trig_dma_pipe = trig_dma_pipe = bus.AxiPipelineStage(
            self.trig_dma.dma_bus_signature.props
        )
        wiring.connect(m, trig_dma.dmabus, trig_dma_pipe.input)
        bus.connect_axi(m, trig_dma_pipe.output, wiring.flipped(self.m_axi_trig))
        m.submodules.postage_dma_pipe = postage_dma_pipe = bus.AxiPipelineStage(
            self.postage_dma.dma_bus_signature.props
        )
        wiring.connect(m, postage_dma.dmabus, postage_dma_pipe.input)
        bus.connect_axi(m, postage_dma_pipe.output, wiring.flipped(self.m_axi_postage))

        m.submodules.pad = pad = StreamPad(trigger_event.size, 64)
        m.submodules.strip = strip = StreamStripper(
            data.StructLayout({"iq": Complex(16), "last": 1}), Complex(16), lambda x: x.iq
        )

        wiring.connect(m, trig_peri.trigger_events, pad.input)
        wiring.connect(m, pad.output, trig_dma.stream)

        wiring.connect(m, trig_peri.postage_events, strip.input)
        wiring.connect(m, strip.output, postage_dma.stream)

        return m


def map_to_json(memory_map):
    import json

    registers = []
    for resource in memory_map.all_resources():
        fields = []
        for k in resource.resource.field:
            fields.append((k, getattr(resource.resource.field, k).port.shape.width))
        registers.append({
            "path": resource.path,
            "start": resource.start,
            "end": resource.end,
            "width": resource.width,
            "fields": fields,
        })
    return json.dumps(registers)


if __name__ == "__main__":
    import sys

    from amaranth.back import verilog

    from .utils import RFSoCGen3Platform

    enable_cuber = True
    if len(sys.argv) > 2:
        enable_cuber = sys.argv[2] == "True"
    integrated_trigger = TriggerSubsystem(enable_cuber)
    with open(sys.argv[1], "w") as f:
        f.write(verilog.convert(integrated_trigger, name="trigger_subsystem", platform=RFSoCGen3Platform()))
    with open(sys.argv[1] + ".json", "w") as fj:
        fj.write(map_to_json(integrated_trigger.decoder.bus.memory_map))
    with open(sys.argv[1] + ".cuber.json", "w") as fj:
        if enable_cuber:
            fj.write(map_to_json(integrated_trigger.decoder_slow.bus.memory_map))
        else:
            fj.write("[]")
