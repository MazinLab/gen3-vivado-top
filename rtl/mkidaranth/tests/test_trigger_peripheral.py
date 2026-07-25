import unittest

from amaranth import *
from amaranth.lib import wiring
from amaranth.sim import Simulator
from amaranth_soc import csr

from mkidaranth.trigger_peripheral import Trigger
from mkidaranth.axi import bus
from mkidaranth.axi.ip import AXIDMA, AXICSRBridge


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
    response = await stream_get(ctx, axi.r)
    return response.data, response.resp


async def axil_wdata(ctx, axi, data):
    await stream_put(ctx, axi.w, {"data": data, "strb": -1})


async def axil_bresp(ctx, axi):
    return (await stream_get(ctx, axi.b)).resp


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


def axi_reciever(self, bus, storage, addr_wait=0, data_wait=0, resp_wait=0):
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
            wlast,
            awready,
            awvalid,
            awaddr,
            awsize,
            awlen,
        ) in ctx.tick().sample(
            bus.w.ready,
            bus.w.valid,
            bus.w.payload.data,
            bus.w.payload.last,
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
                        self.assertEqual(wlast, 1)
                    else:
                        self.assertEqual(wlast, 0)
                if awready & awvalid:
                    address = awaddr
                    incr = 1 << awsize
                    limit = address + (awlen + 1) * incr
                    ctx.set(bus.aw.ready, 0)
                    ctx.set(bus.w.ready, 1)

    return recv


class AXIDMATestCase(unittest.TestCase):
    def test_basicdma(self):
        dut = AXIDMA(burst_length=16, input_fifo=None)

        storage = {}

        async def testbench(ctx):
            for i in range(4):
                await _csr_access(
                    self,
                    ctx,
                    dut.ctlbus,
                    dut.ctlbus.memory_map.find_resource(dut._afifo).start,
                    0,
                    1,
                    i * 8192,
                )
                for j in range(
                    dut.ctlbus.memory_map.find_resource(dut._afifo).start + 1,
                    dut.ctlbus.memory_map.find_resource(dut._afifo).end,
                ):
                    await _csr_access(self, ctx, dut.ctlbus, j, 0, 1, 0)
            await _csr_access(
                self,
                ctx,
                dut.ctlbus,
                dut.ctlbus.memory_map.find_resource(dut._dmactl).start,
                0,
                1,
                2048,
            )
            for i in range(512):
                ctx.set(dut.stream.payload, i)
                ctx.set(dut.stream.valid, 1)
                await ctx.tick().until(dut.stream.ready)
            ctx.set(dut.stream.valid, 0)
            for _ in range(32):
                await ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(self, dut.dmabus, storage))
        with sim.write_vcd("test_peripheral_dma.vcd"):
            sim.run()
        k = 0
        for j in range(4):
            for i in range(0, 2048, dut._bpt):
                self.assertEqual(storage[i + j * 8192], k)
                k += 1

    def test_basicdma_inputfifo(self):
        dut = AXIDMA(burst_length=16, input_fifo=32)

        storage = {}

        async def testbench(ctx):
            await _csr_access(
                self,
                ctx,
                dut.ctlbus,
                dut.ctlbus.memory_map.find_resource(dut._input_fifo_reg).start,
                0,
                1,
                16 << 32,
            )
            for i in range(4):
                await _csr_access(
                    self,
                    ctx,
                    dut.ctlbus,
                    dut.ctlbus.memory_map.find_resource(dut._afifo).start,
                    0,
                    1,
                    i * 8192,
                )
                for j in range(
                    dut.ctlbus.memory_map.find_resource(dut._afifo).start + 1,
                    dut.ctlbus.memory_map.find_resource(dut._afifo).end,
                ):
                    await _csr_access(self, ctx, dut.ctlbus, j, 0, 1, 0)
            await _csr_access(
                self,
                ctx,
                dut.ctlbus,
                dut.ctlbus.memory_map.find_resource(dut._dmactl).start,
                0,
                1,
                2048,
            )
            for i in range(512):
                ctx.set(dut.stream.payload, i)
                ctx.set(dut.stream.valid, 1)
                await ctx.tick().until(dut.stream.ready)
            ctx.set(dut.stream.valid, 0)
            for _ in range(64):
                await ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(self, dut.dmabus, storage))
        with sim.write_vcd("test_peripheral_dma_inputfifo.vcd"):
            sim.run()
        k = 0
        for j in range(4):
            for i in range(0, 2048, dut._bpt):
                self.assertEqual(storage[i + j * 8192], k)
                k += 1

    def test_basicdma_inputfifo_skipping(self):
        dut = AXIDMA(burst_length=16, input_fifo=32)

        storage = {}

        async def testbench(ctx):
            await _csr_access(
                self,
                ctx,
                dut.ctlbus,
                dut.ctlbus.memory_map.find_resource(dut._input_fifo_reg).start,
                0,
                1,
                16 << 32,
            )
            for i in range(4):
                await _csr_access(
                    self,
                    ctx,
                    dut.ctlbus,
                    dut.ctlbus.memory_map.find_resource(dut._afifo).start,
                    0,
                    1,
                    i * 8192 * 2,
                )
                for j in range(
                    dut.ctlbus.memory_map.find_resource(dut._afifo).start + 1,
                    dut.ctlbus.memory_map.find_resource(dut._afifo).end,
                ):
                    await _csr_access(self, ctx, dut.ctlbus, j, 0, 1, 0)
            await _csr_access(
                self,
                ctx,
                dut.ctlbus,
                dut.ctlbus.memory_map.find_resource(dut._dmactl).start,
                0,
                1,
                2048,
            )
            for i in range(512):
                ctx.set(dut.stream.payload, i)
                ctx.set(dut.stream.valid, 1)
                await ctx.tick().until(dut.stream.ready)
            ctx.set(dut.stream.valid, 0)
            for _ in range(64):
                await ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(self, dut.dmabus, storage))
        with sim.write_vcd("test_peripheral_dma_inputfifo.vcd"):
            sim.run()
        k = 0
        for j in range(4):
            for i in range(0, 2048, dut._bpt):
                self.assertEqual(storage[i + j * 8192 * 2], k)
                k += 1


class AXICSRBridgeTestCase(unittest.TestCase):
    class Harness(wiring.Component):

        class RWAReg(csr.Register, access="rw"):
            rwa: csr.Field(csr.action.RW, 32)

        class RWBReg(csr.Register, access="rw"):
            rwb: csr.Field(csr.action.RW, 213)
            rwc: csr.Field(csr.action.RW, 16)

        def __init__(self):
            regs = csr.Builder(addr_width=8, data_width=32)
            self._rwar = regs.add("RWAReg", self.RWAReg())
            self._rwbr = regs.add("RWBReg", self.RWBReg())

            self._bridge = csr.Bridge(regs.as_memory_map())

            self.memory_map = self._bridge.bus.memory_map

            super().__init__(
                {
                    "axi": wiring.In(bus.Signature(bus.Axi4LiteProperties(DATA_WIDTH=32, ADDR_WIDTH=10))),
                    "rwa": wiring.Out(32),
                    "rwb": wiring.Out(213),
                    "rwc": wiring.Out(16),
                }
            )

        def elaborate(self, platform):
            m = Module()

            m.submodules.axibridge = axibridge = AXICSRBridge(addr_width=10, data_width=32)
            wiring.connect(m, wiring.flipped(self.axi), axibridge.axi)

            m.submodules.csrbridge = self._bridge
            wiring.connect(m, axibridge.csr, self._bridge.bus)

            m.d.comb += [
                self.rwa.eq(self._rwar.f.rwa.data),
                self.rwb.eq(self._rwbr.f.rwb.data),
                self.rwc.eq(self._rwbr.f.rwc.data),
            ]

            return m

    def test_readwrite(self):
        dut = self.Harness()

        async def testbench(ctx):
            import random

            g = random.Random(4)
            rwar = dut.memory_map.find_resource(dut._rwar)
            rwbr = dut.memory_map.find_resource(dut._rwbr)

            for _ in range(32):
                r = g.randint(0, (1 << 32) - 1)
                await axil_address(ctx, dut.axi.aw, rwar.start << 2)
                await axil_wdata(ctx, dut.axi, r)
                await axil_bresp(ctx, dut.axi)

                await axil_address(ctx, dut.axi.ar, rwar.start << 2)
                self.assertEqual((await axil_rdata(ctx, dut.axi))[0], r)

                self.assertEqual(ctx.get(dut.rwa), r)

            for _ in range(32):
                r = rc = g.randint(0, (1 << (213 + 16)) - 1)

                for i in range(rwbr.start, rwbr.end):
                    await axil_address(ctx, dut.axi.aw, i << 2)
                    await axil_wdata(ctx, dut.axi, rc & 0xFFFFFFFF)
                    await axil_bresp(ctx, dut.axi)
                    rc = rc >> 32

                rc = r
                await ctx.tick()
                self.assertEqual(ctx.get(dut.rwb), r & ((1 << 213) - 1))
                self.assertEqual(ctx.get(dut.rwc), r >> 213)

                for i in range(rwbr.start, rwbr.end):
                    await axil_address(ctx, dut.axi.ar, i << 2)
                    data = (await axil_rdata(ctx, dut.axi))[0]
                    self.assertEqual(data, rc & 0xFFFFFFFF)
                    rc = rc >> 32

            for _ in range(16):
                await ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_axicsrbridge_readwrite.vcd"):
            sim.run()


class PeripheralTestCase(unittest.TestCase):
    # @unittest.skip("currently broken")
    def test_config(self):
        dut = Trigger(addr_width=8, data_width=64)

        async def testbench(ctx):
            ctx.set(dut.cuber_events.ready, 1)

            async def write_config(bin, threshold, holdoff, postage):
                r = dut.bus.memory_map.find_resource(dut._trigcontrol)
                await _csr_access(
                    self,
                    ctx,
                    dut.bus,
                    r.start,
                    0,
                    1,
                    (
                        (
                            dut._trigcontrol.f.config.w_data.shape().const(
                                {
                                    "bin": bin,
                                    "config": {
                                        "threshold": threshold,
                                        "holdoff": holdoff,
                                        "postage": postage,
                                        "enabled": 1,
                                    },
                                }
                            )
                        ).as_bits()
                        << 1
                    ),
                )

            await _csr_access(
                self,
                ctx,
                dut.bus,
                dut.bus.memory_map.find_resource(dut._valvecontrol).start,
                0,
                1,
                0b000000,
            )

            for _ in range(16):
                await ctx.tick()
            await write_config(0x100, 100, 10, True)
            await write_config(0x101, 99, 11, True)
            await write_config(0x102, 98, 12, False)
            await _csr_access(
                self,
                ctx,
                dut.bus,
                dut.bus.memory_map.find_resource(dut._postcontrol).start,
                0,
                1,
                1 | 1 << 3,
            )

            r = dut.bus.memory_map.find_resource(dut._chunksampler)

            cs = 0
            for j, i in enumerate(range(r.start, r.end)):
                cs |= (await _csr_access(self, ctx, dut.bus, i, 1, 0, 0)) << (64 * j)
            cs = dut._chunksampler.f.chunk_header.r_data.shape().from_bits(cs)

            # TODO: Nail down the 6 cycle fudge factor
            event = await stream_get(ctx, dut.trigger_events)
            self.assertEqual(event.bin, 0x100)
            self.assertEqual(event.phase, -5)
            self.assertEqual(event.read, 1)
            self.assertEqual(event.cycle, 0x03)

            event = await stream_get(ctx, dut.trigger_events)
            self.assertEqual(event.bin, 0x102)
            self.assertEqual(event.phase, -1000)
            self.assertEqual(event.read, 1)
            self.assertEqual(event.cycle, 0x05)

            event = await stream_get(ctx, dut.trigger_events)
            self.assertEqual(event.bin, 0x101)
            self.assertEqual(event.phase, 0)
            self.assertEqual(event.read, 1)
            self.assertEqual(event.cycle, 0x10)

            for _ in range(16):
                await ctx.tick()

            # self.assertEqual(ctx.get(dut._postages[0].output_streams[0].valid), 0)
            # self.assertEqual(ctx.get(dut._postages[1].output_streams[0].valid), 1)
            # self.assertEqual(ctx.get(dut._postages[2].output_streams[0].valid), 0)
            # self.assertEqual(ctx.get(dut._postages[3].output_streams[0].valid), 0)
            # self.assertEqual(
            #     ctx.get(dut._postages[1].output_streams[0].payload.iq.imag), 9
            # )
            # self.assertEqual(ctx.get(dut._postages[1].output_metadata[0].read), 1)
            # self.assertEqual(
            #     ctx.get(dut._postages[1].output_metadata[0].cycle)
            #     + chunkcycle
            #     - 0x101 // 4,
            #     17.0 * 512,
            # )

            for i in range(9, 16):
                self.assertEqual((await stream_get(ctx, dut.postage_events)).iq.imag, i)

            cs = 0
            for j, i in enumerate(range(r.start, r.end)):
                cs |= (await _csr_access(self, ctx, dut.bus, i, 1, 0, 0)) << (64 * j)
            cs = dut._chunksampler.f.chunk_header.r_data.shape().from_bits(cs)
            self.assertEqual(cs.read, 2)
            self.assertEqual(cs.dropped, 0)
            self.assertEqual(cs.fault, 0)
            self.assertEqual(cs.empty, 0)

            cs = 0
            for j, i in enumerate(range(r.start, r.end)):
                cs |= (await _csr_access(self, ctx, dut.bus, i, 1, 0, 0)) << (64 * j)
            cs = dut._chunksampler.f.chunk_header.r_data.shape().from_bits(cs)
            self.assertEqual(cs.read, 3)
            self.assertEqual(cs.dropped, 0)
            self.assertEqual(cs.fault, 0)
            self.assertEqual(cs.empty, 1)

            cs = 0
            for j, i in enumerate(range(r.start, r.end)):
                cs |= (await _csr_access(self, ctx, dut.bus, i, 1, 0, 0)) << (64 * j)
            cs = dut._chunksampler.f.chunk_header.r_data.shape().from_bits(cs)
            self.assertEqual(cs.read, 1)
            self.assertEqual(cs.dropped, 0)
            self.assertEqual(cs.fault, 0)
            self.assertEqual(cs.empty, 1)

        async def pulse_process(ctx):
            ip = 0
            iq = 0
            p = [200, 200, 200, 200]
            for _ in range(8):
                await ctx.tick()

            def update(cycle, bin):
                nonlocal ip
                nonlocal iq
                nonlocal p
                ctx.set(dut.iq.valid, 1)
                ctx.set(
                    dut.iq.payload,
                    {
                        "beat": (iq) % 256,
                        "payload": [{"real": (iq) + j, "imag": cycle} for j in range(8)],
                    },
                )
                ctx.set(dut.phase.valid, 1)
                ctx.set(
                    dut.phase.payload,
                    {
                        "beat": ip % 512,
                        "payload": p,
                    },
                )
                ctx.set(dut.timestamp.payload, {"secs": iq, "ns": ip, "subns": 0xAA})

            update(0, 0)
            async for clk, _, iqr, phaser in ctx.tick().sample(dut.iq.ready, dut.phase.ready):
                if clk:
                    if iqr:
                        iq += 1
                    if phaser:
                        ip += 1
                    cycle = 4 * ip // (2048)
                    bin = (4 * ip) % 2048
                    if cycle == 3 and bin == 0x100:
                        p[0] = -5
                    else:
                        p[0] = 200
                    if cycle == 16 and bin + 1 == 0x101:
                        p[1] = 0
                    else:
                        p[1] = 200
                    if cycle == 5 and bin + 2 == 0x102:
                        p[2] = -1000
                    else:
                        p[2] = 200
                    if cycle == 6 and bin + 3 == 0x103:
                        p[3] = 12
                    else:
                        p[3] = 200
                    update(cycle, bin)

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(pulse_process)
        with sim.write_vcd("test_peripheral_config.vcd"):
            sim.run()
