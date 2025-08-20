import unittest

from amaranth import *
from amaranth.lib import wiring
from amaranth.sim import Simulator

from mkidaranth.integration import TriggerSubsystem, map_to_json
from mkidaranth import axi

async def stream_get(ctx, stream):
    ctx.set(stream.ready, 1)
    (payload,) = await ctx.tick().sample(stream.payload).until(stream.valid)
    ctx.set(stream.ready, 0)
    return payload


async def stream_put(ctx, stream, payload):
    ctx.set(stream.valid, 1)
    ctx.set(stream.payload, payload)
    await ctx.tick().until(stream.ready)
    ctx.set(stream.valid, 0)


async def stream_put_hold(ctx, stream, payload):
    ctx.set(stream.valid, 1)
    ctx.set(stream.payload, payload)
    await ctx.tick().until(stream.ready)

async def axil_address(ctx, awr, addr):
    await stream_put(ctx, awr, {"addr": addr})

async def axil_rdata(ctx, axi):
    response = (await stream_get(ctx, axi.r))
    return response.data, response.resp

async def axil_wdata(ctx, axi, data):
    await stream_put(ctx, axi.w, {"data": data, "strb": -1})

async def axil_bresp(ctx, axi):
    return (await stream_get(ctx, axi.b)).resp

async def axil_read(ctx, axi, addr):
    await axil_address(ctx, axi.ar, addr)
    return (await axil_rdata(ctx, axi))[0]

async def axil_write(ctx, axi, addr, data):
    await axil_address(ctx, axi.aw, addr)
    await axil_wdata(ctx, axi, data)
    await axil_bresp(ctx, axi)

def axi_reciever(bus, storage, addr_wait=lambda: 0, data_wait=lambda: 0, resp_wait=lambda: 0):
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
        ) in ctx.tick().sample(
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
                val |= ((await axil_read(mmio[0], mmio[1], addr << 2)) << (i * 32))
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
                await axil_write(mmio[0], mmio[1], addr << 2, (val >> (i * 32)) & 0xFFFFFFFF)
            return
    assert False

def hr(r):
    for k, v in r.items():
        if k == '_all':
            continue
        print("\t", k, hex(v))

class IntegrationTestCase(unittest.TestCase):
    class IntegrationHarness(wiring.Component):
        def __init__(self, ts):
            self.ts = ts
            
            super().__init__(
                {
                    "s_axi_ctrl": wiring.In(axi.Signature(ts.converter.axi_properties)),
                    "m_axi_trig": wiring.Out(axi.Signature(ts.trig_dma.dma_bus_signature.props)),
                    "m_axi_postage": wiring.Out(axi.Signature(ts.postage_dma.dma_bus_signature.props)),
                }
            )

        def elaborate(self, platform):
            m = Module()
            m.submodules.ts = self.ts

            axi.connect_axi(m, wiring.flipped(self.s_axi_ctrl), self.ts.s_axi_ctrl)
            axi.connect_axi(m, wiring.flipped(self.m_axi_trig), self.ts.m_axi_trig)
            axi.connect_axi(m, wiring.flipped(self.m_axi_postage), self.ts.m_axi_postage)

            m.d.comb += self.ts.aclk.eq(ClockSignal())
            m.d.comb += self.ts.aresetn.eq(~ResetSignal())
            
            return m

    def test_basicdma(self):
        import json
        dut = self.IntegrationHarness(TriggerSubsystem(enable_cuber=False, sim_clocks=True))
        regs = json.loads(map_to_json(dut.ts.decoder.bus.memory_map))
        # print(json.dumps(regs, indent=4))

        storage = {}

        async def testbench(ctx):
            ctrl_mmio = (ctx, dut.s_axi_ctrl)
            await write_reg(ctrl_mmio, regs, ['Trigger', 'ValveControl'], {"trigger": 3, "cuber": 3, "stamper": 3})
            await write_reg(ctrl_mmio, regs, ['TriggerDMA', 'DMAControl'], {
                'buffer_size': 1024,
                'flush': 0,
                'fault': 0
            })
            # print(['Trigger', 'DMAControl'])
            # hr(await read_reg(ctrl_mmio, regs, ['TriggerDMA', 'DMAControl']))
            # print(['Trigger', 'Debug'])
            # hr(await read_reg(ctrl_mmio, regs, ['TriggerDMA', 'Debug']))

            await write_reg(ctrl_mmio, regs, ['TriggerDMA', 'AddressFIFO'], {
                'address': 0xFF00F800,
                'depth': 0,
                'count': 0,
                'lowmark': 1,
            })
            for _ in range(32):
                # print(['Trigger', 'Debug'])
                (await read_reg(ctrl_mmio, regs, ['TriggerDMA', 'Debug']))

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        # sim.add_clock(0.5e-6, domain="slow")
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(dut.m_axi_trig, storage))
        sim.add_process(axi_reciever(dut.m_axi_postage, storage))
        with sim.write_vcd("test_integration_magic.vcd"):
            sim.run()
        # hr(storage)
