import unittest

from amaranth.sim import Simulator

from mkidaranth.trigger_peripheral import Trigger, AXIDMA


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


class AXIDMATestCase(unittest.TestCase):
    def test_basicdma(self):
        dut = AXIDMA(burst_length=16)

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
                ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(axi_reciever(dut.dmabus, storage))
        with sim.write_vcd("test_peripheral_dma.vcd"):
            sim.run()
        print(storage)


class PeripheralTestCase(unittest.TestCase):
    def test_config(self):
        dut = Trigger(addr_width=8, data_width=64)

        async def testbench(ctx):
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
                        dut._trigcontrol.f.config.w_data.shape().const(
                            {
                                "bin": bin,
                                "config": {
                                    "threshold": threshold,
                                    "holdoff": holdoff,
                                    "postage": postage,
                                },
                            }
                        )
                    ).as_bits()
                    << 2,
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
            chunkcycle = cs.timestamp.secs

            for _ in range(16):
                await ctx.tick()
            for _ in range(512 * 32):
                await ctx.tick()
            self.assertEqual(ctx.get(dut._postages[0].output_streams[0].valid), 0)
            self.assertEqual(ctx.get(dut._postages[1].output_streams[0].valid), 1)
            self.assertEqual(ctx.get(dut._postages[2].output_streams[0].valid), 0)
            self.assertEqual(ctx.get(dut._postages[3].output_streams[0].valid), 0)
            self.assertEqual(
                ctx.get(dut._postages[1].output_streams[0].payload.iq.imag), 9
            )
            self.assertEqual(ctx.get(dut._postages[1].output_metadata[0].read), 1)
            self.assertEqual(
                ctx.get(dut._postages[1].output_metadata[0].cycle)
                + chunkcycle
                - 0x101 // 4,
                17.0 * 512,
            )

            self.assertEqual(ctx.get(dut._triggers[0].event_stream.payload.bin), 0x100)
            self.assertEqual(ctx.get(dut._triggers[0].event_stream.payload.phase), -5)
            self.assertEqual(ctx.get(dut._triggers[0].event_stream.payload.read), 1)
            self.assertEqual(
                ctx.get(dut._triggers[0].event_stream.payload.cycle)
                + chunkcycle
                - 0x100 // 4,
                4.0 * 512,
            )
            self.assertEqual(ctx.get(dut._triggers[0].event_stream.valid), 1)

            self.assertEqual(ctx.get(dut._triggers[1].event_stream.payload.bin), 0x101)
            self.assertEqual(ctx.get(dut._triggers[1].event_stream.payload.phase), 0)
            self.assertEqual(ctx.get(dut._triggers[1].event_stream.payload.read), 1)
            self.assertEqual(
                ctx.get(dut._triggers[1].event_stream.payload.cycle)
                + chunkcycle
                - 0x101 // 4,
                17.0 * 512,
            )
            self.assertEqual(ctx.get(dut._triggers[1].event_stream.valid), 1)

            self.assertEqual(ctx.get(dut._triggers[2].event_stream.payload.bin), 0x102)
            self.assertEqual(
                ctx.get(dut._triggers[2].event_stream.payload.phase), -1000
            )
            self.assertEqual(ctx.get(dut._triggers[2].event_stream.payload.read), 1)
            self.assertEqual(
                ctx.get(dut._triggers[2].event_stream.payload.cycle)
                + chunkcycle
                - 0x102 // 4,
                6.0 * 512,
            )
            self.assertEqual(ctx.get(dut._triggers[2].event_stream.valid), 1)

            self.assertEqual(ctx.get(dut._triggers[3].event_stream.valid), 0)

            for t in dut._triggers:
                if ctx.get(t.event_stream.valid):
                    ctx.set(t.event_stream.ready, 1)
                    await ctx.tick()
                    ctx.set(t.event_stream.ready, 0)
            await ctx.tick()

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
            async for clk, _, iqr, phaser in ctx.tick().sample(
                dut.iq.ready, dut.phase.ready
            ):
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

                if clk:
                    if iq % 2 == 0:
                        ctx.set(dut.iq.valid, 1)
                    else:
                        ctx.set(dut.iq.valid, 0)
                    ctx.set(
                        dut.iq.payload,
                        {
                            "beat": (iq // 2) % 256,
                            "payload": [
                                {"real": (iq) + j, "imag": cycle} for j in range(8)
                            ],
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
                    ctx.set(
                        dut.timestamp.payload, {"secs": iq, "ns": ip, "subns": 0xAA}
                    )
                    if iqr:
                        iq += 1
                    if phaser:
                        ip += 1

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(pulse_process)
        with sim.write_vcd("test_peripheral_config.vcd"):
            sim.run()
