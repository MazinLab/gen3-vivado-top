import unittest

from amaranth import *
from amaranth.lib import wiring, stream
from amaranth.sim import Simulator

from mkidaranth.integration import TriggerSubsystem, map_to_json
from mkidaranth.trigger import iq_stream, phase_stream
from mkidaranth.axi import bus

from dataclasses import dataclass

async def stream_get(ctx, stream, domain="sync"):
    ctx.set(stream.ready, 1)
    (payload,) = await ctx.tick(domain).sample(stream.payload).until(stream.valid)
    ctx.set(stream.ready, 0)
    return payload


async def stream_put(ctx, stream, payload, domain="sync"):
    ctx.set(stream.valid, 1)
    ctx.set(stream.payload, payload)
    await ctx.tick(domain).until(stream.ready)
    ctx.set(stream.valid, 0)


async def stream_put_hold(ctx, stream, payload, domain="sync"):
    ctx.set(stream.valid, 1)
    ctx.set(stream.payload, payload)
    await ctx.tick(domain).until(stream.ready)

async def axil_address(ctx, awr, addr, domain="sync"):
    await stream_put(ctx, awr, {"addr": addr}, domain)

async def axil_rdata(ctx, axi, domain="sync"):
    response = (await stream_get(ctx, axi.r, domain))
    return response.data, response.resp

async def axil_wdata(ctx, axi, data, domain="sync"):
    await stream_put(ctx, axi.w, {"data": data, "strb": -1}, domain)

async def axil_bresp(ctx, axi, domain="sync"):
    return (await stream_get(ctx, axi.b, domain)).resp

async def axil_read(ctx, axi, addr, domain="sync"):
    await axil_address(ctx, axi.ar, addr, domain)
    return (await axil_rdata(ctx, axi, domain))[0]

async def axil_write(ctx, axi, addr, data, domain="sync"):
    await axil_address(ctx, axi.aw, addr, domain)
    await axil_wdata(ctx, axi, data, domain)
    await axil_bresp(ctx, axi, domain)

def pulse_process(self, stream, mark, cyc):
    i = 0

    def update(ctx, stream, mark, cyc):
        nonlocal i
        ctx.set(stream.valid, 1)
        ctx.set(stream.payload.beat, i)
        pulse = False
        for j in range(4):
            bin = (j + i * 4) % 2048
            cycle = (j + i * 4) // 2048
            if bin == 0 and (cycle == 32):
                pulse = True
                ctx.set(stream.payload.payload[j], 10)
            else:
                ctx.set(stream.payload.payload[j], bin + 10000)
            ctx.set(cyc, cycle)
        if pulse:
            ctx.set(mark, 1)
        else:
            ctx.set(mark, 0)

    async def process(ctx):
        for _ in range(32):
            await ctx.tick()
        started = False
        update(ctx, stream, mark, cyc)
        async for edge, _, valid, ready in ctx.tick().sample(stream.valid, stream.ready):
            nonlocal i
            if edge & valid & ready:
                i += 1
                started = True
                update(ctx, stream, mark, cyc)
            if edge & started:
                self.assertEqual(ready, 1)

    return process

def pulse_process_iq(self, stream):
    i = 0
    def update(ctx, stream):
        nonlocal i
        ctx.set(stream.valid, 1)
        ctx.set(stream.payload.beat, i)
        for j in range(8):
            bin = (j + i * 8) % 2048
            cycle = (j + i * 8) // 2048
            ctx.set(stream.payload.payload[j].real, bin)
            ctx.set(stream.payload.payload[j].imag, cycle)

    async def process(ctx):
        nonlocal i
        for _ in range(8):
            await ctx.tick()
        started = False
        unready = 0
        update(ctx, stream)
        async for edge, _, valid, ready in ctx.tick().sample(stream.valid, stream.ready):
            if edge & valid & ready:
                i += 1
                unready = 0
                started = True
                update(ctx, stream)
            if edge & started and unready > 1:
                self.assertEqual(ready, 1)
    return process


def axi_reciever(bus, storage, addr_wait=lambda: 0, data_wait=lambda: 0, resp_wait=lambda: 0, domain="sync"):
    async def recv(ctx):
        address = 0
        incr = 0
        limit = 0
        ctx.set(bus.aw.ready, 1)
        ctx.set(bus.b.valid, 1)
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
        ) in ctx.tick(domain).sample(
            bus.w.ready,
            bus.w.valid,
            bus.w.payload.data,
            bus.aw.ready,
            bus.aw.valid,
            bus.aw.payload.addr,
            bus.aw.payload.size,
            bus.aw.payload.len,
        ):
            if edge:
                if wready & wvalid:
                    storage[address] = wdata
                    address += incr
                    if address == limit:
                        ctx.set(bus.w.ready, 0)
                        ctx.set(bus.aw.ready, 1)
                if awready & awvalid:
                    address = awaddr
                    incr = 1 << awsize
                    limit = address + (awlen + 1) * incr
                    ctx.set(bus.aw.ready, 0)
                    ctx.set(bus.w.ready, 1)

    return recv

async def read_reg(mmio, regs, path):
    for reg in regs:
        if [r[0] for r in reg['path']] == path:
            val = 0
            for i, addr in enumerate(range(reg['start'], reg['end'])):
                val |= ((await axil_read(mmio[0], mmio[1], addr << 2, domain=mmio[2])) << (i * 32))
            vals = {}
            valc = val
            for k, v in reg['fields']:
                vals[k] = valc & ((1 << v) - 1)
                valc = valc >> v
            vals["_all"] = val
            return vals

async def write_reg(mmio, regs, path, fields):
    for reg in regs:
        if [r[0] for r in reg['path']] == path:
            val = 0
            acc = 0
            for k, v in reg['fields']:
                val |= (fields[k] & ((1 << v) - 1)) << acc
                acc += v
            for i, addr in enumerate(range(reg['start'], reg['end'])):
                await axil_write(mmio[0], mmio[1], addr << 2, (val >> (i * 32)) & 0xFFFFFFFF, domain=mmio[2])
            return
    assert False

def hr(r):
    for k, v in r.items():
        if k == '_all':
            continue
        print("\t", k, hex(v))

class HuskyDMASim:
    def __init__(self, mmio, regs, path):
        if type(path) is str:
            path = [path]
        self.path = path
        self.mmio = mmio
        self.regs = regs

    async def debug(self):
        return await read_reg(self.mmio, self.regs, self.path + ['Debug'])

    async def print_debug(self):
        hr(await self.debug())

    async def fifo_status(self):
        return (await read_reg(self.mmio, self.regs, self.path + ['AddressFIFO']))

    async def dma_status(self):
        return (await read_reg(self.mmio, self.regs, self.path + ['DMAControl']))

    async def completed(self):
        if (await self.fifo_status())['count'] != 0:
            return False
        d = await self.debug()
        if d['address_wait'] or d['data_wait']:
            return True
        return False

    async def fifo_ready(self):
        s = await self.fifo_status()
        return s['count'] < s['depth']

    async def push_buffer(self, buffer):
        if buffer.nbytes != (await self.dma_status())['buffer_size']:
            while not await self.completed():
                pass
        await write_reg(self.mmio, self.regs, self.path + ['DMAControl'], {
            'buffer_size': buffer.nbytes,
            'flush': 0,
            'fault': 0
        })
        while not await self.fifo_ready():
            pass
        await write_reg(self.mmio, self.regs, self.path + ['AddressFIFO'], {
            'address': buffer.physical_address,
            'depth': 0,
            'count': 0,
            'lowmark': 1,
        })

def trig_config(b, threshold, holdoff, postage=False, enabled=False):
    cw = 0
    cw |= b & ((1 << 11) - 1)
    cw |= (threshold & ((1 << 16) - 1)) << 11
    cw |= (holdoff & ((1 << 8) - 1)) << (11 + 16)
    if postage:
        cw |= 1 << (11 + 16 + 8)
    if enabled:
        cw |= 1 << (11 + 16 + 8 + 1)
    return cw

async def write_trigconfig(ctrl_mmio, regs, b, threshold, holdoff, postage=False, prescale=True, input_gate=False, enabled=False):
    cw = trig_config(b, threshold, holdoff, postage, enabled)
    await write_reg(ctrl_mmio, regs, ['Trigger', 'TriggerControl'], {
        "prescale": 1 if prescale else 0,
        "input_gate": 1 if input_gate else 0,
        "config": cw
    })

@dataclass
class SimBuffer:
    nbytes: int
    physical_address: int = 0

class IntegrationTestCase(unittest.TestCase):
    class IntegrationHarness(wiring.Component):
        def __init__(self, ts):
            self.ts = ts

            from mkidaranth.image_cuber_perhipheral import cuber_axi_signature
            super().__init__(
                {
                    "s_axi_ctrl": wiring.In(bus.Signature(ts.converter.axi_properties)),
                    "s_axi_ctrl_slow": wiring.In(bus.Signature(ts.converter.axi_properties)),
                    "s_axi_cube": wiring.In(bus.Signature(cuber_axi_signature.props)),
                    "m_axi_trig": wiring.Out(bus.Signature(ts.trig_dma.dma_bus_signature.props)),
                    "m_axi_postage": wiring.Out(bus.Signature(ts.postage_dma.dma_bus_signature.props)),
                    "s_axis_iq": wiring.In(stream.Signature(iq_stream._payload_shape)),
                    "s_axis_phase": wiring.In(stream.Signature(phase_stream._payload_shape)),
                    "pulse_mark_sim": wiring.In(1),
                    "cycle_mark_sim": wiring.In(32)
                }
            )

        def elaborate(self, platform):
            m = Module()
            m.submodules.ts = self.ts

            pms = Signal()
            cms = Signal(32)
            m.d.comb += pms.eq(self.pulse_mark_sim)
            m.d.comb += cms.eq(self.cycle_mark_sim)

            bus.connect_axi(m, wiring.flipped(self.s_axi_ctrl), self.ts.s_axi_ctrl)
            bus.connect_axi(m, wiring.flipped(self.s_axi_ctrl_slow), self.ts.s_axi_ctrl_slow)
            bus.connect_axi(m, wiring.flipped(self.s_axi_cube), self.ts.s_axi_cube)
            bus.connect_axi(m, wiring.flipped(self.m_axi_trig), self.ts.m_axi_trig)
            bus.connect_axi(m, wiring.flipped(self.m_axi_postage), self.ts.m_axi_postage)
            bus.connect(m, wiring.flipped(self.s_axis_iq), self.ts.s_axis_iq)
            bus.connect(m, wiring.flipped(self.s_axis_phase), self.ts.s_axis_phase)

            m.d.comb += self.ts.aclk.eq(ClockSignal())
            m.d.comb += self.ts.aresetn.eq(~ResetSignal())

            return m

    #@unittest.skip("Skip")
    def test_basicdma(self):
        import json
        dut = self.IntegrationHarness(TriggerSubsystem(enable_cuber=False, sim_clocks=True))
        regs = json.loads(map_to_json(dut.ts.decoder.bus.memory_map))

        storage = {}

        async def testbench(ctx):
            ctrl_mmio = (ctx, dut.s_axi_ctrl, "sync")
            await write_reg(ctrl_mmio, regs, ['Trigger', 'ValveControl'], {"trigger": 3, "cuber": 3, "stamper": 3})
            tmimo = HuskyDMASim(ctrl_mmio, regs, 'TriggerDMA')
            fb1 = SimBuffer(8192, 0)
            await tmimo.push_buffer(fb1)
            while not await tmimo.completed():
                pass

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(dut.m_axi_trig, storage))
        sim.add_process(axi_reciever(dut.m_axi_postage, storage))
        with sim.write_vcd("test_integration_magic.vcd"):
            sim.run()

    """
    def test_cuber(self):
        import json
        dut = self.IntegrationHarness(TriggerSubsystem(enable_cuber=True, sim_clocks=True))
        regs = json.loads(map_to_json(dut.ts.decoder.bus.memory_map))
        regs_cuber = json.loads(map_to_json(dut.ts.decoder_slow.bus.memory_map))

        storage = {}

        async def testbench(ctx):
            ctrl_mmio = (ctx, dut.s_axi_ctrl, "sync")
            ctrl_mmio_cuber = (ctx, dut.s_axi_ctrl_slow, "slow")
            await write_reg(ctrl_mmio, regs, ['Trigger', 'ValveControl'], {"trigger": 3, "cuber": 3, "stamper": 3})
            await write_reg(ctrl_mmio_cuber, regs_cuber, ["CuberDMA", "CPF"], {'cpf': 2560})
            await write_reg(ctrl_mmio_cuber, regs_cuber, ["CuberDMA", "RunCuber"], {'generate_cubes': 1})
            await ctx.tick("slow").repeat(3000)
            ctx.set(dut.s_axi_cube.ar.payload.addr, 0)
            ctx.set(dut.s_axi_cube.ar.payload.burst, 1)
            ctx.set(dut.s_axi_cube.ar.payload.len, 0)
            ctx.set(dut.s_axi_cube.ar.payload.size, 2)
            ctx.set(dut.s_axi_cube.ar.payload.id, 15)
            ctx.set(dut.s_axi_cube.ar.valid, 1)
            await ctx.tick("slow")
            ctx.set(dut.s_axi_cube.ar.valid, 0)
            await ctx.tick("slow").repeat(20)
            ctx.set(dut.s_axi_cube.r.ready, 1)
            await ctx.tick("slow").repeat(4000)
            ctx.set(dut.s_axi_cube.ar.payload.addr, 0)
            ctx.set(dut.s_axi_cube.ar.payload.burst, 1)
            ctx.set(dut.s_axi_cube.ar.payload.len, 0)
            ctx.set(dut.s_axi_cube.ar.payload.size, 2)
            ctx.set(dut.s_axi_cube.ar.payload.id, 14)
            ctx.set(dut.s_axi_cube.ar.valid, 1)
            await ctx.tick("slow")
            ctx.set(dut.s_axi_cube.ar.valid, 0)
            await ctx.tick("slow").repeat(2)
            ctx.set(dut.s_axi_cube.r.ready, 1)
            await ctx.tick("slow").repeat(3000)

        sim = Simulator(dut)
        sim.add_clock(2e-9)
        sim.add_clock(4e-9, domain="slow")
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(dut.m_axi_trig, storage))
        sim.add_process(axi_reciever(dut.m_axi_postage, storage))
        with sim.write_vcd("test_integration_cuber.vcd"):
            sim.run()
    """

    def test_integration_cuber(self):
        import json
        dut = self.IntegrationHarness(TriggerSubsystem(enable_cuber=True, sim_clocks=True))
        regs = json.loads(map_to_json(dut.ts.decoder.bus.memory_map))
        regs_cuber = json.loads(map_to_json(dut.ts.decoder_slow.bus.memory_map))

        storage = {}

        def pixelLUTdata(BIN, x, y):
            data = 0
            data |= BIN
            data |= (x << 11)
            data |= (y << 15)
            return data

        def wavelengthLUTdata(BIN, edge0, edge1, edge2, edge3, edge4):
            def to_unsigned_equiv(i):
                return int.from_bytes(int.to_bytes(i, 2, 'little', signed=True), 'little')

            data = 0
            data |= BIN
            data |= (to_unsigned_equiv(edge0) << 11)
            data |= (to_unsigned_equiv(edge1) << (11+16))
            data |= (to_unsigned_equiv(edge2) << (11+(16*2)))
            data |= (to_unsigned_equiv(edge3) << (11+(16*3)))
            data |= (to_unsigned_equiv(edge4) << (11+(16*4)))
            return data

        #Generate sample pixel and wavelength LUTs for cuber
        async def generate_sample_LUTS(ctx, ctrl_cuber_mmio):
            addr = 0
            for xx in range(1):
                for yy in range(2):
                    await write_reg(ctrl_cuber_mmio, regs_cuber, ['CuberDMA', 'pixelLUTconfig'], {
                            "pixelLUTconfig": pixelLUTdata(addr, xx, yy)
                        })
                    await ctx.tick("slow")
                    addr += 1

            addr = 0
            for _ in range(1):
                await write_reg(ctrl_cuber_mmio, regs_cuber, ['CuberDMA', 'wavelengthLUTconfig'], {
                        "wavelengthLUTconfig": wavelengthLUTdata(addr, -32500, -1024, 1024, 8096, 32500)
                    })
                await ctx.tick("slow")
                addr += 1

        async def testbench(ctx):
            ctrl_mmio = (ctx, dut.s_axi_ctrl, "sync")
            ctrl_mmio_cuber = (ctx, dut.s_axi_ctrl_slow, "slow")
            tmimo = HuskyDMASim(ctrl_mmio, regs, 'TriggerDMA')
            fb1 = SimBuffer(8192, 0)
            await tmimo.push_buffer(fb1)
            await write_trigconfig(ctrl_mmio, regs, 0, 50, 4, input_gate = False, prescale=True, enabled=True, postage=False)
            await write_reg(ctrl_mmio_cuber, regs_cuber, ["CuberDMA", "CPF"], {'cpf': 2560})
            await generate_sample_LUTS(ctx, ctrl_mmio_cuber)
            await write_reg(ctrl_mmio_cuber, regs_cuber, ["CuberDMA", "RunCuber"], {'generate_cubes': 1})
            while not ((await read_reg(ctrl_mmio_cuber, regs_cuber, ["CuberDMA", "debugRegister"]))["photon_count"]==1):
                pass
            await ctx.tick("slow").repeat(2550)
            ctx.set(dut.s_axi_cube.ar.payload.addr, 0b1000000000000000)
            ctx.set(dut.s_axi_cube.ar.payload.burst, 1)
            ctx.set(dut.s_axi_cube.ar.payload.len, 0)
            ctx.set(dut.s_axi_cube.ar.payload.size, 3)
            ctx.set(dut.s_axi_cube.ar.valid, 1)
            await ctx.tick("slow")
            ctx.set(dut.s_axi_cube.ar.valid, 0)
            await ctx.tick("slow")
            await ctx.posedge(dut.s_axi_cube.r.valid)
            ctx.set(dut.s_axi_cube.r.ready, 1)
            self.assertGreater(ctx.get(dut.s_axi_cube.r.payload.data), 0)
            await ctx.tick("slow").repeat(20)

        sim = Simulator(dut)
        sim.add_clock(2e-9)
        sim.add_clock(4e-9, domain="slow")
        sim.add_testbench(testbench)
        sim.add_process(pulse_process(self, dut.s_axis_phase, dut.pulse_mark_sim, dut.cycle_mark_sim))
        sim.add_process(pulse_process_iq(self, dut.s_axis_iq))
        sim.add_process(axi_reciever(dut.m_axi_trig, storage))
        #sim.add_process(axi_reciever(dut.m_axi_postage, storage))
        with sim.write_vcd("test_integration_cuber.vcd"):
            sim.run()

        for k, v in storage.items():
            if k == 0:
                self.assertEqual(v & 0xFFFF, 10)
                self.assertEqual(v >> 16, 32)
            if k >= 8192:
                self.assertEqual(v & 0xFFFF, 0)
                self.assertEqual(v >> 16, ((k - 8192) // 4) + 32 - 8 + 1)


    @unittest.skip("Skip")
    def test_trigger(self):
        import json
        dut = self.IntegrationHarness(TriggerSubsystem(enable_cuber=False, sim_clocks=True))
        regs = json.loads(map_to_json(dut.ts.decoder.bus.memory_map))

        storage = {}

        async def testbench(ctx):
            ctrl_mmio = (ctx, dut.s_axi_ctrl, "sync")
            tmimo = HuskyDMASim(ctrl_mmio, regs, 'TriggerDMA')
            pmimo = HuskyDMASim(ctrl_mmio, regs, 'PostageDMA')
            fb1 = SimBuffer(8192, 0)
            fb2 = SimBuffer(4 * 128, 8192)
            await write_trigconfig(ctrl_mmio, regs, 0, 50, 4, input_gate = False, prescale=True, enabled=True, postage=True)
            await write_reg(ctrl_mmio, regs, ['Trigger', 'PostageControl'], {
                'count': 1,
                'dropped': 0,
                'fault': 0,
                'flushed': 0,
            })
            await tmimo.push_buffer(fb1)
            await pmimo.push_buffer(fb2)
            while not await pmimo.completed():
                pass

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(pulse_process(self, dut.s_axis_phase, dut.pulse_mark_sim, dut.cycle_mark_sim))
        sim.add_process(pulse_process_iq(self, dut.s_axis_iq))
        sim.add_process(axi_reciever(dut.m_axi_trig, storage))
        sim.add_process(axi_reciever(dut.m_axi_postage, storage))
        with sim.write_vcd("test_integration_trigger.vcd"):
            sim.run()

        for k, v in storage.items():
            if k == 0:
                self.assertEqual(v, 10)
            if k >= 8192:
                self.assertEqual(v & 0xFFFF, 0)
                self.assertEqual(v >> 16, ((k - 8192) // 4) + 32 - 8 + 1)
