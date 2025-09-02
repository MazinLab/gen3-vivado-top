import unittest
from amaranth import *
from amaranth.sim import Simulator
from amaranth.lib.wiring import In, Out, Component
from amaranth.lib import wiring
from mkidaranth.image_cuber_perhipheral import CuberPeri
from src.mkidaranth.trigger import CYCLE_BITS
from src.mkidaranth import axi
from .test_cuber import Producer
from .test_trigger import stream_get, stream_put

aw = 16
dw = 32
ones = 0
for i in range(dw):
    ones = ones + (2**i)

class Harness(Component):
    test_phase: In(signed(16))
    test_bin: In(11)
    test_cycle: In(CYCLE_BITS)
    photon_event: In(1)
    valid: In(1)
    membus: In(axi.Signature(axi.Axi4Properties(QOS_Present=False, PROT_Present=False, CACHE_Present=False, Exclusive_Accesses=False, READ_WRITE_MODE=axi.ReadWriteMode.READ_ONLY, ADDR_WIDTH=16, REGION_Present=False, DATA_WIDTH=64, WSTRB_Present=False, WLAST_Present=False, ID_W_WIDTH=0, ID_R_WIDTH=16)))
    cycle_counter: Out(CYCLE_BITS)
    
    def __init__(self):
        self.cuber_peri = CuberPeri(csr_addr_width=aw, csr_data_width=dw)
        super().__init__()

    def elaborate(self, platform):
        m = Module()

        m.d.sync += self.cycle_counter.eq(self.cycle_counter + 1)

        m.submodules.producer = producer = Producer()
        m.submodules.cuber_peri = cuber_peri = self.cuber_peri

        self.cuber_peri = cuber_peri

        m.d.comb += [
            cuber_peri.trigger_stream.payload.eq(producer.event_stream.payload),
            cuber_peri.trigger_stream.valid.eq(producer.event_stream.valid),
            producer.event_stream.ready.eq(cuber_peri.trigger_stream.ready)
        ]

        wiring.connect(m, wiring.flipped(self.membus), cuber_peri.membus)

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



async def _csr_access(self, ctx, bus, addr, r_stb=0, w_stb=0, w_data=0):
    ctx.set(bus.addr, addr)
    ctx.set(bus.r_stb, r_stb)
    ctx.set(bus.w_stb, w_stb)
    ctx.set(bus.w_data, w_data)
    await ctx.tick()
    if r_stb:
        ret = ctx.get(bus.r_data)
    else:
        ret = None
    ctx.set(bus.r_stb, 0)
    ctx.set(bus.w_stb, 0)
    return ret


class PeripheralTestCase(unittest.TestCase):
    #@unittest.skip("Skip")
    def test_config(self):
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


        async def testbench(ctx):
            async def write_cpf(cpf):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, cpf)
            
            async def write_generate(run):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, run)
            
            async def write_pixelLUT(bin, x, y):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._pixelLUTconfig)
                data = (dut.cuber_peri._pixelLUTconfig.f.pixelLUTconfig.w_data.shape().const({"bin": bin,"xpos": x,"ypos": y})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def generate_sample_pixel_LUT():
                addr = 0
                for xx in range(14):
                    for yy in range(146):
                        await write_pixelLUT(addr, xx, yy)
                        addr += 1
            
            async def generate_sample_wavelength_LUT():
                addr = 0
                for _ in range(2048):
                    await write_wavelengthLUT(addr, 0b0000000100000000, 0b0000001100000000, 0b0000011100000000, 0b0001111100000000, 0b0111111100000000)
                    addr += 1

            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 0)
            await write_cpf(2561)
            await ctx.tick().repeat(5)
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.cycles_per_frame), 2561)
            self.assertEqual(await _csr_access(self, ctx, dut.cuber_peri.bus, addr=dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf).start, r_stb=1, w_stb=0, w_data=0), 2561)
            await ctx.tick()
            await generate_sample_pixel_LUT()
            await generate_sample_wavelength_LUT()
            await ctx.tick()
            await write_generate(1)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 1)
            await ctx.tick()
            self.assertEqual(await _csr_access(self, ctx, dut.cuber_peri.bus, addr=dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber).start, r_stb=1, w_stb=0, w_data=0), 1)



        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_config.vcd"):
            sim.run()

    #@unittest.skip("Skip")
    def test_interrupt(self):
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


        async def testbench(ctx):
            async def write_cpf(cpf):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, cpf)
            
            async def write_generate(run):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, run)
            
            async def write_pixelLUT(bin, x, y):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._pixelLUTconfig)
                data = (dut.cuber_peri._pixelLUTconfig.f.pixelLUTconfig.w_data.shape().const({"bin": bin,"xpos": x,"ypos": y})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def generate_sample_pixel_LUT():
                addr = 0
                for xx in range(14):
                    for yy in range(146):
                        await write_pixelLUT(addr, xx, yy)
                        addr += 1
            
            async def generate_sample_wavelength_LUT():
                addr = 0
                for _ in range(2048):
                    await write_wavelengthLUT(addr, 0b0000000100000000, 0b0000001100000000, 0b0000011100000000, 0b0001111100000000, 0b0111111100000000)
                    addr += 1

            await ctx.tick()
            await write_cpf(2560)
            await ctx.tick()
            await generate_sample_pixel_LUT()
            await generate_sample_wavelength_LUT()
            await ctx.tick()
            await write_generate(1)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.int), 0)
            for j in range(3000):
                generate_photon_event(ctx, 570, 200+j)
                await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.int), 1)
            r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._errorcounts)
            await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 1, 0, 0)
            await _csr_access(self, ctx, dut.cuber_peri.bus, r.start+1, 1, 0, 0)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.int), 0)
            await ctx.tick().repeat(20)



        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_interrupt.vcd"):
            sim.run()
    

    #@unittest.skip("Skip")
    def test_axi(self):
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

        async def testbench(ctx):
            async def write_cpf(cpf):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, cpf)
            
            async def write_generate(run):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, run)
            
            async def write_pixelLUT(bin, x, y):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._pixelLUTconfig)
                data = (dut.cuber_peri._pixelLUTconfig.f.pixelLUTconfig.w_data.shape().const({"bin": bin,"xpos": x,"ypos": y})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def generate_sample_pixel_LUT():
                addr = 0
                for xx in range(14):
                    for yy in range(146):
                        await write_pixelLUT(addr, xx, yy)
                        addr += 1
            
            async def generate_sample_wavelength_LUT():
                addr = 0
                for _ in range(2048):
                    await write_wavelengthLUT(addr, 0b0000000100000000, 0b0000001100000000, 0b0000011100000000, 0b0001111100000000, 0b0111111100000000)
                    addr += 1

            async def await_last_while_valid(membus):
                while True:
                    if ((ctx.get(membus.r.valid) == 1) and (ctx.get(membus.r.payload.last) == 1)):
                        break
                    else:
                        await ctx.tick()
            
            async def axi_burst(burst_len, burst_size, burst_type, start_addr, id=0):
                ctx.set(dut.membus.ar.payload.len, burst_len-1)
                ctx.set(dut.membus.ar.payload.size, burst_size)
                ctx.set(dut.membus.ar.payload.burst, burst_type)
                ctx.set(dut.membus.ar.payload.addr, start_addr)
                ctx.set(dut.membus.ar.payload.id, id)
                ctx.set(dut.membus.ar.valid, 1)
                await ctx.negedge(dut.membus.ar.ready)
                ctx.set(dut.membus.ar.valid, 0)
                await ctx.posedge(dut.membus.r.valid)
                ctx.set(dut.membus.r.ready, 1)

            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 0)
            await write_cpf(2561)
            await ctx.tick().repeat(5)
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.cycles_per_frame), 2561)
            await ctx.tick()
            await generate_sample_pixel_LUT()
            await generate_sample_wavelength_LUT()
            await ctx.tick()
            await write_generate(1)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 1)
            await ctx.tick()
            generate_photon_event(ctx, 570, 200)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 800, 202)
            await ctx.tick().repeat(1035)
            generate_photon_event(ctx, 4097, 200)
            await ctx.tick().repeat(2200)
            
            
            await axi_burst(16, 3, 1, 0b0000100101100000)
            #await axi_burst(5, 3, 1, 310*8)
            for j in range(16):
                if (j == 10):
                    self.assertEqual(ctx.get(dut.membus.r.payload.data), 0b00000000_00000001_00000000_00000001)
                if (j == 12):
                    self.assertEqual(ctx.get(dut.membus.r.payload.data), 0b00000000_00000000_00000001_00000000)
                if (j == 15):
                    self.assertEqual(ctx.get(dut.membus.r.payload.last), 1)
                await stream_get(ctx, dut.membus.r)
            ctx.set(dut.membus.r.ready, 0)
            
            await ctx.tick().repeat(30)
            generate_photon_event(ctx, 500, 203)
            await ctx.tick()
            generate_photon_event(ctx, 100, 203)
            await ctx.tick().repeat(1035)
            generate_photon_event(ctx, 500, 1371)
            await ctx.tick()
            generate_photon_event(ctx, 502, 1371)
            await ctx.tick()
            generate_photon_event(ctx, 4097, 1371)
            await ctx.tick().repeat(2000)

            await axi_burst(16, 3, 1, 0b1000100101100000)
            for j in range(16):
                if (j == 13):
                    self.assertEqual(ctx.get(dut.membus.r.payload.data), 0b00000001_00000000_00000010_00000000_00000000_00000000_00000001)   
                if (j == 15):
                    self.assertEqual(ctx.get(dut.membus.r.payload.last), 1)
                await stream_get(ctx, dut.membus.r)
            ctx.set(dut.membus.r.ready, 0)

            await ctx.tick().repeat(5)
            cycle_num = ctx.get(dut.test_cycle)
            await axi_burst(16, 3, 1, 0b0000100101100000)   #This burst is called on mem1 while mem1 does not have read access
            await await_last_while_valid(dut.membus)
            await ctx.tick()
            ctx.set(dut.membus.r.ready, 0)
            self.assertGreater(ctx.get(dut.test_cycle) - cycle_num, 100)    #Check here that it took a lot of time before the burst happened
                                                                            #since it had to wait for the cuber to allow mem1 read access
            
            await ctx.tick().repeat(2520)
            cycle_num = ctx.get(dut.test_cycle)
            await axi_burst(250, 3, 1, 0b0000100101100000)   #This burst is called on mem1 while mem1 has read access
                                                                #BUT it is called too close to the end of the mem1 read access stage
                                                                #In other words, the burst is still be in progress when mem1 access stops
            await await_last_while_valid(dut.membus)
            await ctx.tick()
            ctx.set(dut.membus.r.ready, 0)
            self.assertGreater(ctx.get(dut.test_cycle) - cycle_num, 2560)   #Check here that it took > a full cycle before the burst finished
                                                                            #since it had to wait for the entire mem1 clear/count cycle before
                                                                            #being able to access mem1 again
            
            await ctx.tick().repeat(260)
            await axi_burst(1, 3, 1, 0b0000100101100000)
            self.assertEqual(ctx.get(dut.cuber_peri.membus.r.payload.last), 1)
            await ctx.tick()
            ctx.set(dut.membus.r.ready, 0)
            await ctx.tick().repeat(10)

            await axi_burst(100, 3, 1, 0b0000100101100000)
            await ctx.tick().repeat(15)
            ctx.set(dut.membus.r.ready, 0)
            await ctx.tick().repeat(15)
            p1 = ctx.get(dut.cuber_peri.cuber.mem_read.payload.addr)
            await ctx.tick().repeat(15)
            p2 = ctx.get(dut.cuber_peri.cuber.mem_read.payload.addr)
            await ctx.tick().repeat(15)
            self.assertEqual(p1, p2)
            await ctx.tick()
            ctx.set(dut.membus.r.ready, 1)
            await await_last_while_valid(dut.membus)
            await ctx.tick()
            ctx.set(dut.membus.r.ready, 0)
            await ctx.tick().repeat(1880)
            await ctx.tick().repeat(4)
            ctx.set(dut.membus.r.ready, 1)
            await axi_burst(1, 3, 1, 0)
            await ctx.tick()
            await axi_burst(1, 3, 1, 32768)
            await ctx.tick().repeat(50)

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_axi.vcd"):
            sim.run()

    #@unittest.skip("Skip")
    def test_reading_from_zero(self):
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

        async def testbench(ctx):
            async def write_cpf(cpf):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, cpf)
            
            async def write_generate(run):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, run)
            
            async def write_pixelLUT(bin, x, y):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._pixelLUTconfig)
                data = (dut.cuber_peri._pixelLUTconfig.f.pixelLUTconfig.w_data.shape().const({"bin": bin,"xpos": x,"ypos": y})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def generate_sample_pixel_LUT():
                addr = 0
                for xx in range(14):
                    for yy in range(146):
                        await write_pixelLUT(addr, xx, yy)
                        addr += 1
            
            async def generate_sample_wavelength_LUT():
                addr = 0
                for _ in range(2048):
                    await write_wavelengthLUT(addr, 0b0000000100000000, 0b0000001100000000, 0b0000011100000000, 0b0001111100000000, 0b0111111100000000)
                    addr += 1

            async def await_last_while_valid(membus):
                while True:
                    if ((ctx.get(membus.r.valid) == 1) and (ctx.get(membus.r.payload.last) == 1)):
                        break
                    else:
                        await ctx.tick()
            
            async def axi_burst(burst_len, burst_size, burst_type, start_addr, id=0):
                ctx.set(dut.membus.ar.payload.len, burst_len-1)
                ctx.set(dut.membus.ar.payload.size, burst_size)
                ctx.set(dut.membus.ar.payload.burst, burst_type)
                ctx.set(dut.membus.ar.payload.addr, start_addr)
                ctx.set(dut.membus.ar.payload.id, id)
                ctx.set(dut.membus.ar.valid, 1)
                await ctx.negedge(dut.membus.ar.ready)
                ctx.set(dut.membus.ar.valid, 0)
                await ctx.posedge(dut.membus.r.valid)
                ctx.set(dut.membus.r.ready, 1)

            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 0)
            await write_cpf(2561)
            await ctx.tick().repeat(5)
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.cycles_per_frame), 2561)
            await ctx.tick()
            await generate_sample_pixel_LUT()
            await generate_sample_wavelength_LUT()
            await ctx.tick()
            await write_generate(1)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 1)
            await ctx.tick()
            generate_photon_event(ctx, 570, 200)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 800, 202)
            await ctx.tick().repeat(1035)
            generate_photon_event(ctx, 4097, 200)
            await ctx.tick().repeat(100)
            
            
            await axi_burst(1, 2, 0, 0, id=9)

            await ctx.tick().repeat(2000)
            

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_reading_from_zero.vcd"):
            sim.run()

    #@unittest.skip("Skip")
    def test_negative_phase(self):
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

        async def testbench(ctx):
            async def write_cpf(cpf):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, cpf)
            
            async def write_generate(run):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, run)
            
            async def write_pixelLUT(bin, x, y):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._pixelLUTconfig)
                data = (dut.cuber_peri._pixelLUTconfig.f.pixelLUTconfig.w_data.shape().const({"bin": bin,"xpos": x,"ypos": y})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def generate_sample_pixel_LUT():
                addr = 0
                for xx in range(14):
                    for yy in range(146):
                        await write_pixelLUT(addr, xx, yy)
                        addr += 1
            
            async def generate_sample_wavelength_LUT():
                addr = 0
                for _ in range(2048):
                    await write_wavelengthLUT(addr, -5000, -3000, -1000, 1000, 5000)
                    addr += 1

            async def await_last_while_valid(membus):
                while True:
                    if ((ctx.get(membus.r.valid) == 1) and (ctx.get(membus.r.payload.last) == 1)):
                        break
                    else:
                        await ctx.tick()
            
            async def axi_burst(burst_len, burst_size, burst_type, start_addr, id=0):
                ctx.set(dut.membus.ar.payload.len, burst_len-1)
                ctx.set(dut.membus.ar.payload.size, burst_size)
                ctx.set(dut.membus.ar.payload.burst, burst_type)
                ctx.set(dut.membus.ar.payload.addr, start_addr)
                ctx.set(dut.membus.ar.payload.id, id)
                ctx.set(dut.membus.ar.valid, 1)
                await ctx.negedge(dut.membus.ar.ready)
                ctx.set(dut.membus.ar.valid, 0)
                await ctx.posedge(dut.membus.r.valid)
                ctx.set(dut.membus.r.ready, 1)

            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 0)
            await write_cpf(2560)
            await ctx.tick().repeat(5)
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.cycles_per_frame), 2560)
            await ctx.tick()
            await generate_sample_pixel_LUT()
            await generate_sample_wavelength_LUT()
            await ctx.tick()
            await write_generate(1)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 1)
            await ctx.tick()
            generate_photon_event(ctx, -4000, 200)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, -6000, 200)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, -100, 202)
            await ctx.tick().repeat(1035)
            generate_photon_event(ctx, 2000, 200)
            await ctx.tick().repeat(2000)
            
            
            await axi_burst(4, 3, 1, 310*8)
            self.assertEqual(ctx.get(dut.membus.r.payload.data), 0x01000001)

            await ctx.tick().repeat(100)
            

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_negative_phase.vcd"):
            sim.run()

    #@unittest.skip("Skip")
    def test_constant_photons(self):
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

        async def testbench(ctx):
            async def write_cpf(cpf):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._cpf)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, cpf)
            
            async def write_generate(run):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._runcuber)
                await _csr_access(self, ctx, dut.cuber_peri.bus, r.start, 0, 1, run)
            
            async def write_pixelLUT(bin, x, y):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._pixelLUTconfig)
                data = (dut.cuber_peri._pixelLUTconfig.f.pixelLUTconfig.w_data.shape().const({"bin": bin,"xpos": x,"ypos": y})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (dw*i)) & ones
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def generate_sample_pixel_LUT():
                addr = 0
                for xx in range(14):
                    for yy in range(146):
                        await write_pixelLUT(addr, xx, yy)
                        addr += 1
            
            async def generate_sample_wavelength_LUT():
                addr = 0
                for _ in range(2048):
                    await write_wavelengthLUT(addr, 0b0000000100000000, 0b0000001100000000, 0b0000011100000000, 0b0001111100000000, 0b0111111100000000)
                    addr += 1

            async def await_last_while_valid(membus):
                while True:
                    if ((ctx.get(membus.r.valid) == 1) and (ctx.get(membus.r.payload.last) == 1)):
                        break
                    else:
                        await ctx.tick()
            
            async def axi_burst(burst_len, burst_size, burst_type, start_addr, id=0):
                ctx.set(dut.membus.ar.payload.len, burst_len-1)
                ctx.set(dut.membus.ar.payload.size, burst_size)
                ctx.set(dut.membus.ar.payload.burst, burst_type)
                ctx.set(dut.membus.ar.payload.addr, start_addr)
                ctx.set(dut.membus.ar.payload.id, id)
                ctx.set(dut.membus.ar.valid, 1)
                await ctx.negedge(dut.membus.ar.ready)
                ctx.set(dut.membus.ar.valid, 0)
                await ctx.posedge(dut.membus.r.valid)
                ctx.set(dut.membus.r.ready, 1)

            await ctx.tick()
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.generate_cubes), 0)
            await write_cpf(2560)
            await ctx.tick().repeat(5)
            self.assertEqual(ctx.get(dut.cuber_peri.cuber.cycles_per_frame), 2560)
            await ctx.tick()
            await generate_sample_pixel_LUT()
            await generate_sample_wavelength_LUT()
            await ctx.tick()
            for i in range(2049):
                generate_photon_event(ctx, 570, 200)
                await ctx.tick()
            await write_generate(1)
            for i in range(2590):
                generate_photon_event(ctx, 570, 200)
                await ctx.tick()
            await ctx.tick().repeat(12000)
            self.assertEqual(ctx.get(dut.cuber_peri.trigger_stream.ready), 1)
            

        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_constant_photons.vcd"):
            sim.run()