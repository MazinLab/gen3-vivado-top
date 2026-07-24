import unittest

from amaranth import *
from amaranth.lib import wiring, stream, data
from amaranth.sim import Simulator

from mkidaranth import axi
from mkidaranth.pulser import PulseCommand, Pulser, BUS_PROPS
from mkidaranth.integration import map_to_json
from mkidaranth.pulser import PulserIntegration

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

class PulserTestCase(unittest.TestCase):
    def test_pulser(self):
        dut = Pulser()

        async def testbench(ctx):
            ctx.set(dut.iin.payload, [0x7fff for _ in range(4)])
            ctx.set(dut.qin.payload, [0x7fff for _ in range(4)])
            ctx.set(dut.iin.valid, 1)
            ctx.set(dut.qin.valid, 1)
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.CMUL,
                    "info": {
                        "cmul": {
                            "real": 0x8000,
                            "imag": 0x0000
                        }
                    }
                }
            )
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.SET,
                    "info": {
                        "set": {
                            "shr": [3, 3, 3, 3]
                        }
                    }
                }
            )
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.DELAY,
                    "info": {
                        "delay": {
                            "delay": 32
                        }
                    }
                }
            )
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.SET,
                    "info": {
                        "set": {
                            "shr": [2, 2, 2, 2]
                        }
                    }
                }
            )
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.DELAY,
                    "info": {
                        "delay": {
                            "delay": 32
                        }
                    }
                }
            )
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.SET,
                    "info": {
                        "set": {
                            "shr": [0, 0, 0, 0]
                        }
                    }
                }
            )
            await stream_put(
                ctx,
                dut.command,
                {
                    "command": PulseCommand.Command.DELAY,
                    "info": {
                        "delay": {
                            "delay": 32
                        }
                    }
                }
            )
            for i in range(0, 32768, 16):
                await stream_put(
                    ctx,
                    dut.command,
                    {
                        "command": PulseCommand.Command.CMUL,
                        "info": {
                            "cmul": {
                                "real": i,
                                "imag": 0x0000
                            }
                        }
                    }
                )

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_pulser.vcd"):
            sim.run()

class PulserIntegrationTestCase(unittest.TestCase):
    class IntegrationHarness(wiring.Component):
        def __init__(self, ts):
            self.ts = ts

            super().__init__(
                {
                    "s_axi_pulser": wiring.In(axi.Signature(BUS_PROPS)),
                    "iin": wiring.In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                    "qin": wiring.In(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                    "iout": wiring.Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                    "qout": wiring.Out(stream.Signature(data.ArrayLayout(signed(16), 8), always_ready=True)),
                    "pps": wiring.In(1),
                }
            )

        def elaborate(self, platform):
            m = Module()
            m.submodules.ts = self.ts

            axi.connect_axi(m, wiring.flipped(self.s_axi_pulser), self.ts.s_axi_pulser)
            axi.connect(m, wiring.flipped(self.iin), self.ts.s_axis_iin)
            axi.connect(m, wiring.flipped(self.qin), self.ts.s_axis_qin)
            axi.connect(m, self.ts.m_axis_iout, wiring.flipped(self.iout))
            axi.connect(m, self.ts.m_axis_qout, wiring.flipped(self.qout))

            m.d.comb += self.ts.pps.eq(self.pps)

            return m

    def test_fifo(self):
        dut = self.IntegrationHarness(PulserIntegration())

        async def testbench(ctx):
            import json
            ctrl_mmio = (ctx, dut.s_axi_pulser, "sync")
            regs = json.loads(map_to_json(dut.ts.pulser_peri.ctlbus.memory_map))
            print(regs)

            ctx.set(dut.iin.payload, [0x7fff for _ in range(8)])
            ctx.set(dut.qin.payload, [0x7fff for _ in range(8)])

            await write_reg(ctrl_mmio, regs, ["CommandFIFO"], {
                "command": 2 | 0x1 << 4
            })
            for i in range(0, 16):
                await write_reg(ctrl_mmio, regs, ["CommandFIFO"], {
                    "command": 0 | (0x11111111 * i) << 4,
                })
                await write_reg(ctrl_mmio, regs, ["CommandFIFO"], {
                    "command": 1 | (31) << 4,
                })
            for _ in range(32):
                await ctx.tick()
            ctx.set(dut.pps, 1)
            await ctx.tick()
            ctx.set(dut.pps, 0)
            while (await read_reg(ctrl_mmio, regs, ["CommandFIFOStatus"]))['count']:
                pass
           

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_integration_pulser.vcd"):
            sim.run()
