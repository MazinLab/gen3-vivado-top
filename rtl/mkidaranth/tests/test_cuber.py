from amaranth import *
from amaranth.sim import Simulator
from amaranth.lib.wiring import In, Out, Component
from amaranth.lib import stream
from src.mkidaranth.image_cuber import ImageCuber
import unittest
from src.mkidaranth.trigger import trigger_event, CYCLE_BITS

class Producer(Component):
    event_stream: Out(stream.Signature(trigger_event))

    def elaborate(self, platform):
        m = Module()

        with m.If((self.event_stream.valid == 1) & (self.event_stream.ready == 1)):
            m.d.sync += self.event_stream.valid.eq(0)
        
        return m


class Harness(Component):
    test_phase: In(signed(16))
    test_bin: In(11)
    test_cycle: In(CYCLE_BITS)
    photon_event: In(1)
    valid: In(1)
    cycle_counter: Out(CYCLE_BITS)
    
    def __init__(self):
        super().__init__()

    def elaborate(self, platform):
        m = Module()

        m.d.sync += self.cycle_counter.eq(self.cycle_counter + 1)

        m.submodules.producer = producer = Producer()
        m.submodules.cuber = cuber = ImageCuber()

        m.d.comb += cuber.cycles_per_frame.eq(2560)

        m.d.comb += [
            cuber.i_stream.payload.eq(producer.event_stream.payload),
            cuber.i_stream.valid.eq(producer.event_stream.valid),
            producer.event_stream.ready.eq(cuber.i_stream.ready)
        ]

        cycle_last = Signal(CYCLE_BITS)

        with m.If(self.photon_event):
            m.d.comb += producer.event_stream.payload.cycle.eq(self.test_cycle)
            m.d.sync += cycle_last.eq(self.test_cycle)
            m.d.sync += self.photon_event.eq(0)
        with m.Else():
            m.d.comb += producer.event_stream.payload.cycle.eq(cycle_last)

        m.d.comb += producer.event_stream.payload.phase.eq(self.test_phase)
        m.d.comb += producer.event_stream.payload.bin.eq(self.test_bin)
        m.d.comb += producer.event_stream.valid.eq(self.valid)
        
        with m.If(producer.event_stream.ready == 1):
            m.d.sync += self.valid.eq(0)

        return m




dut = Harness()

def generate_photon_event(ctx, phase, bin):
    ctx.set(dut.test_phase, phase)
    ctx.set(dut.test_bin, bin)
    ctx.set(dut.photon_event, 1)
    ctx.set(dut.valid, 1)

async def process_counter(ctx):
    cycle = 0
    async for clk_edge, rst in ctx.tick():
        if rst:
            cycle = 0
        if clk_edge:
            cycle = cycle + 1
        ctx.set(dut.test_cycle, cycle)

class CuberTest(unittest.TestCase):
    def test_cuber(self):
        async def testbench(ctx):
            ctx.set(dut.test_phase, 0)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 570, 200)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 800, 202)
            await ctx.tick().repeat(1035)
            generate_photon_event(ctx, 4097, 200)
            await ctx.tick().repeat(2040)

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_cuber.vcd"):
            sim.run()