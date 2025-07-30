from amaranth.sim import Simulator
from src.mkidaranth.image_cuber import Harness
import unittest



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