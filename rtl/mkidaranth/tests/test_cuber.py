from amaranth import *
from amaranth.sim import Simulator
from amaranth.lib.wiring import In, Out, Component
from amaranth.lib import stream, wiring, data, enum, fifo, memory
from amaranth.lib.memory import Memory, WritePort, ReadPort
from src.mkidaranth.image_cuber import ImageCuber
import unittest
from src.mkidaranth.trigger import trigger_event, CYCLE_BITS

test_wavelength_cutoff_precision = 8

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
    valid_photon: In(1)
    cycle_counter: Out(CYCLE_BITS)
    
    def __init__(self):
        self.cuber = ImageCuber(wavelength_cutoff_precision = test_wavelength_cutoff_precision)
        super().__init__()

    def elaborate(self, platform):
        m = Module()

        m.d.sync += self.cycle_counter.eq(self.cycle_counter + 1)

        m.submodules.producer = producer = Producer()
        m.submodules.cuber = cuber = self.cuber

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
        m.d.comb += producer.event_stream.valid.eq(self.valid_photon)
        
        with m.If(producer.event_stream.ready == 1):
            m.d.sync += self.valid_photon.eq(0)

        return m





class CuberTest(unittest.TestCase):
    #@unittest.skip("Not ready yet")
    def test_cuber(self):
        dut = Harness()

        def generate_photon_event(ctx, phase, bin):
            ctx.set(dut.test_phase, phase)
            ctx.set(dut.test_bin, bin)
            ctx.set(dut.photon_event, 1)
            ctx.set(dut.valid_photon, 1)

        async def process_counter(ctx):
            cycle = 0
            async for clk_edge, rst in ctx.tick():
                if rst:
                    cycle = 0
                if clk_edge:
                    cycle = cycle + 1
                ctx.set(dut.test_cycle, cycle)

        async def generate_sample_pixel_LUT(ctx):
            addr = 0
            ctx.set(dut.cuber.pixel_LUT_write.en, 1)
            for xx in range(14):
                for yy in range(146):
                    ctx.set(dut.cuber.pixel_LUT_write.addr, addr)
                    ctx.set(dut.cuber.pixel_LUT_write.data, (xx<<8) | yy)
                    await ctx.tick()
                    addr += 1
            ctx.set(dut.cuber.pixel_LUT_write.en, 0)

        async def generate_sample_wavelength_LUT(ctx):
            addr = 0
            ctx.set(dut.cuber.wavelength_LUT_write.en, 1)
            for _ in range(2048):
                ctx.set(dut.cuber.wavelength_LUT_write.addr, addr)
                ctx.set(dut.cuber.wavelength_LUT_write.data, 0b0111111100011111000001110000001100000001)
                await ctx.tick()
                addr += 1
            ctx.set(dut.cuber.wavelength_LUT_write.en, 0)
        
        async def read_address_and_assert_equal(ctx, addr, expected_value, mem_num):
            ctx.set(dut.cuber.mem_read_output.ready, 1)

            ctx.set(dut.cuber.mem_read.payload.addr, addr)
            ctx.set(dut.cuber.mem_read.payload.mem_num, mem_num)
            ctx.set(dut.cuber.mem_read.valid, 1)
            
            if (ctx.get(dut.cuber.mem_read.ready)):
                await ctx.tick()
                ctx.set(dut.cuber.mem_read.valid, 0)
            else:
                await ctx.posedge(dut.cuber.mem_read.ready)
                await ctx.tick()
                ctx.set(dut.cuber.mem_read.valid, 0)
            
            if (ctx.get(dut.cuber.mem_read_output.valid)): 
                self.assertEqual(ctx.get(dut.cuber.mem_read_output.payload.data), expected_value)
                self.assertEqual(ctx.get(dut.cuber.mem_read_output.payload.mem_num), mem_num)
            else:
                await ctx.posedge(dut.cuber.mem_read_output.valid)
                await ctx.tick()
                self.assertEqual(ctx.get(dut.cuber.mem_read_output.payload.data), expected_value)
                self.assertEqual(ctx.get(dut.cuber.mem_read_output.payload.mem_num), mem_num)
            
            ctx.set(dut.cuber.mem_read_output.ready, 0)

        async def testbench(ctx):
            ctx.set(dut.cuber.cycles_per_frame, 2560)
            await ctx.tick().repeat(5)
            await generate_sample_pixel_LUT(ctx)
            await ctx.tick().repeat(2)
            await generate_sample_wavelength_LUT(ctx)
            await ctx.tick().repeat(4)
            ctx.set(dut.cuber.generate_cubes, 1)
            await ctx.tick().repeat(2)
            generate_photon_event(ctx, 570, 200)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 800, 202)
            await ctx.tick().repeat(1200)
            generate_photon_event(ctx, 4097, 200)
            await ctx.tick().repeat(2000)
            await read_address_and_assert_equal(ctx, 0b00100110110, 0b00000000_00000001_00000000_00000001, mem_num = 0)
            await read_address_and_assert_equal(ctx, 0b00100110111, 0, mem_num = 0)
            await read_address_and_assert_equal(ctx, 0b00100111000, 0b00000000_00000000_00000001_00000000, mem_num = 0)
            await ctx.tick().repeat(1000)
            generate_photon_event(ctx, 900, 203)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 200, 203)  #Wavelength does not all into in any wavelength bin, so photon shouldn't be counted
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 500, 1371)
            await ctx.tick().repeat(2500)
            await read_address_and_assert_equal(ctx, 0b00100111001, 0b00000001_00000000_00000000_00000001_00000000, mem_num = 1)
            ctx.set(dut.cuber.generate_cubes, 0)
            await ctx.tick().repeat(10)

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_cuber.vcd"):
            sim.run()

    #@unittest.skip("Not ready yet")
    def test_fifo_overflow(self):
        dut = Harness()

        def generate_photon_event(ctx, phase, bin):
            ctx.set(dut.test_phase, phase)
            ctx.set(dut.test_bin, bin)
            ctx.set(dut.photon_event, 1)
            ctx.set(dut.valid_photon, 1)

        async def process_counter(ctx):
            cycle = 0
            async for clk_edge, rst in ctx.tick():
                if rst:
                    cycle = 0
                if clk_edge:
                    cycle = cycle + 1
                ctx.set(dut.test_cycle, cycle)

        async def generate_sample_pixel_LUT(ctx):
            addr = 0
            ctx.set(dut.cuber.pixel_LUT_write.en, 1)
            for xx in range(14):
                for yy in range(146):
                    ctx.set(dut.cuber.pixel_LUT_write.addr, addr)
                    ctx.set(dut.cuber.pixel_LUT_write.data, (xx<<8) | yy)
                    await ctx.tick()
                    addr += 1
            ctx.set(dut.cuber.pixel_LUT_write.en, 0)

        async def generate_sample_wavelength_LUT(ctx):
            addr = 0
            ctx.set(dut.cuber.wavelength_LUT_write.en, 1)
            for _ in range(2048):
                ctx.set(dut.cuber.wavelength_LUT_write.addr, addr)
                ctx.set(dut.cuber.wavelength_LUT_write.data, 0b0111111100011111000001110000001100000001)
                await ctx.tick()
                addr += 1
            ctx.set(dut.cuber.wavelength_LUT_write.en, 0)


        async def testbench(ctx):
            ctx.set(dut.cuber.cycles_per_frame, 2560)
            await ctx.tick().repeat(5)
            await generate_sample_pixel_LUT(ctx)
            await ctx.tick().repeat(2)
            await generate_sample_wavelength_LUT(ctx)
            await ctx.tick().repeat(4)
            ctx.set(dut.cuber.generate_cubes, 1)
            await ctx.tick().repeat(2)
            for _ in range(3000):
                generate_photon_event(ctx, 570, 200)
                await ctx.tick()
            generate_photon_event(ctx, 570, 200)
            self.assertEqual(ctx.get(dut.cuber.lost_photon_flag), 1)
            await ctx.tick().repeat(2)
            self.assertEqual(ctx.get(dut.cuber.lost_photon_flag), 0)

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_fifo_overflow.vcd"):
            sim.run()

    #@unittest.skip("Not ready yet")
    def test_count_overflow(self):
        dut = Harness()

        def generate_photon_event(ctx, phase, bin):
            ctx.set(dut.test_phase, phase)
            ctx.set(dut.test_bin, bin)
            ctx.set(dut.photon_event, 1)
            ctx.set(dut.valid_photon, 1)

        async def process_counter(ctx):
            cycle = 0
            async for clk_edge, rst in ctx.tick():
                if rst:
                    cycle = 0
                if clk_edge:
                    cycle = cycle + 1
                ctx.set(dut.test_cycle, cycle)

        async def generate_sample_pixel_LUT(ctx):
            addr = 0
            ctx.set(dut.cuber.pixel_LUT_write.en, 1)
            for xx in range(14):
                for yy in range(146):
                    ctx.set(dut.cuber.pixel_LUT_write.addr, addr)
                    ctx.set(dut.cuber.pixel_LUT_write.data, (xx<<8) | yy)
                    await ctx.tick()
                    addr += 1
            ctx.set(dut.cuber.pixel_LUT_write.en, 0)

        async def generate_sample_wavelength_LUT(ctx):
            addr = 0
            ctx.set(dut.cuber.wavelength_LUT_write.en, 1)
            for _ in range(2048):
                ctx.set(dut.cuber.wavelength_LUT_write.addr, addr)
                ctx.set(dut.cuber.wavelength_LUT_write.data, 0b0111111100011111000001110000001100000001)
                await ctx.tick()
                addr += 1
            ctx.set(dut.cuber.wavelength_LUT_write.en, 0)


        async def testbench(ctx):
            ctx.set(dut.cuber.cycles_per_frame, 7000)
            await ctx.tick().repeat(5)
            await generate_sample_pixel_LUT(ctx)
            await ctx.tick().repeat(2)
            await generate_sample_wavelength_LUT(ctx)
            await ctx.tick().repeat(4)
            ctx.set(dut.cuber.generate_cubes, 1)
            await ctx.tick().repeat(2)
            for _ in range(255):
                generate_photon_event(ctx, 570, 200)
                await ctx.tick()
            await ctx.tick().repeat(4000)
            generate_photon_event(ctx, 570, 200)
            await ctx.posedge(dut.cuber.count_overflow_flag)

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_count_overflow.vcd"):
            sim.run()