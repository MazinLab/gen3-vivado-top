import unittest

from amaranth.sim import Simulator
from mkidaranth.image_cuber_perhipheral import CuberPeri, Harness

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

def axi_reciever(bus, storage, addr_wait=0, data_wait=0, resp_wait=0):
    async def recv(ctx):
        address = 0
        incr = 0
        limit = 0
        ctx.set(bus.awready, 1)
        ctx.set(bus.bvalid, 1)
        async for (
            edge,
            _,
            wready,
            wvalid,
            wdata,
            awready,
            awvalid,
            awaddr,
            awsize,
            awlen,
        ) in ctx.tick().sample(
            bus.wready,
            bus.wvalid,
            bus.wdata,
            bus.awready,
            bus.awvalid,
            bus.awaddr,
            bus.awsize,
            bus.awlen,
        ):
            if edge:
                if wready & wvalid:
                    storage[address] = wdata
                    address += incr
                    if address == limit:
                        ctx.set(bus.wready, 0)
                        ctx.set(bus.awready, 1)
                if awready & awvalid:
                    address = awaddr
                    incr = 1 << awsize
                    limit = address + (awlen + 1) * incr
                    ctx.set(bus.awready, 0)
                    ctx.set(bus.wready, 1)

    return recv


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

class PeripheralTestCase(unittest.TestCase):
    def test_config(self):
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
                    cyc_dat = (data >> (16*i)) & 0xffff
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def write_wavelengthLUT(bin, edge0, edge1, edge2, edge3, edge4):
                r = dut.cuber_peri.bus.memory_map.find_resource(dut.cuber_peri._wavelengthLUTconfig)
                data = (dut.cuber_peri._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.shape().const({"bin": bin,"edge0": edge0,"edge1": edge1,"edge2": edge2,"edge3": edge3,"edge4": edge4})).as_bits()
                for i in range(r.end-r.start):
                    cyc_dat = (data >> (16*i)) & 0xffff
                    await _csr_access(self, ctx, dut.cuber_peri.bus, r.start + i, 0, 1, cyc_dat)
            
            async def axi_burst(burst_len, burst_size, burst_type, start_addr, id):
                ctx.set(dut.membus.ar.payload.len, burst_len)
                ctx.set(dut.membus.ar.payload.size, burst_size)
                ctx.set(dut.membus.ar.payload.burst, burst_type)
                ctx.set(dut.membus.ar.payload.addr, start_addr)
                ctx.set(dut.membus.ar.payload.id, id)
                ctx.set(dut.membus.ar.valid, 1)
                await ctx.tick()
                ctx.set(dut.membus.ar.valid, 0)
                await ctx.tick().repeat(4)
                ctx.set(dut.membus.r.ready, 1)
                await ctx.tick()
                ctx.set(dut.membus.r.ready, 0)


            await ctx.tick()
            await write_cpf(2560)
            await ctx.tick().repeat(5)
            ctx.set(dut.test_phase, 0)
            await ctx.tick().repeat(5)
            generate_photon_event(ctx, 580, 200)
            await ctx.tick().repeat(2)
            generate_photon_event(ctx, 1000, 202)
            await ctx.tick().repeat(2)
            generate_photon_event(ctx, 2049, 200)
            await ctx.tick().repeat(4)
            await write_generate(1)
            await ctx.tick().repeat(4)
            #await write_pixelLUT(1, 1, 1)
            #await write_pixelLUT(2, 0, 1)
            await ctx.tick().repeat(2)
            for j in range(8):
                await axi_burst(0b11111111, 0b011, 1, 256*8*j, 0)
                await ctx.tick().repeat(256)
            #await write_wavelengthLUT(5, 0b0000000100000000, 0b0000001100000000, 0b0000111100000000, 0b0011111100000000, 0b0111111100000000)
            await ctx.tick().repeat(500)
            await axi_burst(20, 3, 1, 2440, 0)
            await ctx.tick().repeat(3100)
            await axi_burst(16, 0b011, 1, 0, 3)
            await ctx.tick().repeat(1000)
            for j in range(16):
                await _csr_access(self, ctx, dut.cuber_peri.bus, j, 1, 0, 0)
                await ctx.tick()
            await ctx.tick().repeat(5)



        sim = Simulator(dut)
        sim.add_clock(3.90625e-9)
        sim.add_testbench(testbench)
        sim.add_process(process_counter)

        with sim.write_vcd("test_cuber_peri.vcd"):
            sim.run()