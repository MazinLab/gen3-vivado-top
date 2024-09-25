import unittest

from amaranth.sim import Simulator

from mkidaranth.trigger import *


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


class PackageTestCase(unittest.TestCase):
    def test_alignment_fault(self):
        dut = PackageStreams()

        iqpc = lambda i: {
            "beat": i,
            "payload": data.ArrayLayout(iq, 8).from_bits(
                sum([n << (j * 32) for j, n in enumerate(range(i * 8, (i + 1) * 8))])
            ),
        }
        phasepc = lambda i: {
            "beat": i,
            "payload": data.ArrayLayout(signed(16), 4).from_bits(
                sum([n << (j * 16) for j, n in enumerate(range(i * 4, (i + 1) * 4))])
            ),
        }

        packagedpc = lambda i: data.StructLayout(
            {
                "beat": 9,
                "iq": data.ArrayLayout(data.StructLayout({"real": signed(16), "imag": signed(16)}), 4),
                "phase": data.ArrayLayout(signed(16), 4),
            }
        ).const(
            {
                "beat": i,
                "iq": data.ArrayLayout(iq, 4).from_bits(
                    sum([n << (j * 32) for j, n in enumerate(range(i * 4, (i + 1) * 4))])
                ),
                "phase": data.ArrayLayout(signed(16), 4).from_bits(
                    sum([n << (j * 16) for j, n in enumerate(range(i * 4, (i + 1) * 4))])
                ),
            }
        )

        async def testbench(ctx):
            ctx.set(dut.iq.payload, iqpc(0))
            ctx.set(dut.iq.valid, 1)
            for _ in range(10):
                self.assertEqual(ctx.get(dut.packaged.valid), 0)
                self.assertEqual(ctx.get(dut.fault), 0)
                await ctx.tick()
            ctx.set(dut.phase.payload, phasepc(0))
            ctx.set(dut.phase.valid, 1)
            self.assertEqual(ctx.get(dut.packaged.valid), 1)
            self.assertEqual(ctx.get(dut.fault), 0)
            self.assertEqual(ctx.get(dut.packaged.payload), packagedpc(0))
            await ctx.tick()
            ctx.set(dut.iq.valid, 0)
            ctx.set(dut.iq.payload, iqpc(0))
            ctx.set(dut.phase.payload, phasepc(1))
            self.assertEqual(ctx.get(dut.packaged.valid), 1)
            self.assertEqual(ctx.get(dut.fault), 0)
            self.assertEqual(ctx.get(dut.packaged.payload), packagedpc(1))
            await ctx.tick()
            for i in range(1, 32):
                ctx.set(dut.phase.payload, phasepc(2 * i))
                ctx.set(dut.iq.valid, 1)
                ctx.set(dut.iq.payload, iqpc(i))
                self.assertEqual(ctx.get(dut.packaged.valid), 1)
                self.assertEqual(ctx.get(dut.fault), 0)
                self.assertEqual(ctx.get(dut.packaged.payload), packagedpc(2 * i))
                await ctx.tick()

                ctx.set(dut.iq.valid, 0)
                ctx.set(dut.iq.payload, iqpc(0))
                ctx.set(dut.phase.payload, phasepc(2 * i + 1))
                self.assertEqual(ctx.get(dut.packaged.valid), 1)
                self.assertEqual(ctx.get(dut.fault), 0)
                self.assertEqual(ctx.get(dut.packaged.payload), packagedpc(2 * i + 1))
                await ctx.tick()

            i = 33
            ctx.set(dut.iq.valid, 1)
            ctx.set(dut.iq.payload, iqpc(0))
            ctx.set(dut.phase.payload, phasepc(2 * i))
            self.assertEqual(ctx.get(dut.fault), 1)
            await ctx.tick()

            ctx.set(dut.iq.valid, 0)
            ctx.set(dut.iq.payload, iqpc(0))
            ctx.set(dut.phase.payload, phasepc(2 * i + 1))
            self.assertEqual(ctx.get(dut.fault), 1)
            await ctx.tick()

            i = 34
            ctx.set(dut.iq.valid, 1)
            ctx.set(dut.iq.payload, iqpc(i))
            ctx.set(dut.phase.payload, phasepc(2 * i))
            self.assertEqual(ctx.get(dut.fault), 1)
            await ctx.tick()

            ctx.set(dut.iq.valid, 0)
            ctx.set(dut.iq.payload, iqpc(0))
            ctx.set(dut.phase.payload, phasepc(2 * i + 1))
            self.assertEqual(ctx.get(dut.fault), 1)
            await ctx.tick()
            self.assertEqual(ctx.get(dut.fault), 1)

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_alignment.vcd"):
            sim.run()


class Trigger1xTestCase(unittest.TestCase):
    def test_trigger(self):
        dut = Trigger1x()

        async def process_counter(ctx):
            cycle = 0
            read = 0
            async for clk_edge, rst, pvalid in ctx.tick().sample(dut.postage_stream.valid):
                if rst:
                    cycle = 0
                    read = 0
                if clk_edge:
                    cycle = cycle + 1
                    if cycle % 32 == 16:
                        read = 1 + cycle % 3
                ctx.set(dut.read, read)
                ctx.set(dut.cycle, cycle)
                self.assertEqual(pvalid, 0)

        async def process_loopback(ctx):
            async for output_state in ctx.changed(dut.output_state):
                ctx.set(dut.input_state, output_state[0])

        async def testbench(ctx):
            ctx.set(dut.config.threshold, -10)
            ctx.set(dut.config.holdoff, 32)
            ctx.set(dut.config.postage, 0)

            for _ in range(4):
                await ctx.tick()
                self.assertEqual(ctx.get(dut.output_state.state), TriggerState.State.RESET.value)

            for v in [-30, -20, -5, -4, 100, -10]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const({"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}),
                )
                self.assertEqual(ctx.get(dut.output_state.state), TriggerState.State.WAITING.value)

            for v in [-20, -30, -40, -50, -40, -20]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const({"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}),
                )

            self.assertEqual(
                await stream_get(ctx, dut.event_stream),
                trigger_event.const({"phase": -50, "bin": 32, "read": 0, "cycle": 14}),
            )

            for v in [-10, -5, -20, -4, -40, -20, -10]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const({"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}),
                )
                self.assertEqual(ctx.get(dut.event_stream.valid), 0)

            for v in range(24):
                self.assertEqual(ctx.get(dut.output_state.state), TriggerState.State.HOLDING.value)
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const({"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}),
                )

            self.assertEqual(ctx.get(dut.output_state.state), TriggerState.State.WAITING.value)
            self.assertEqual(ctx.get(dut.output_state.info.waiting.maxseen), 23)

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_process(process_counter)
        sim.add_process(process_loopback)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_trigger1x.vcd"):
            sim.run()

    def test_drop(self):
        dut = Trigger1x()

        async def process_counter(ctx):
            cycle = 0
            read = 0
            async for clk_edge, rst in ctx.tick():
                if rst:
                    cycle = 0
                    read = 0
                if clk_edge:
                    cycle = cycle + 1
                    if cycle % 32 == 16:
                        read = 1 + cycle % 3
                ctx.set(dut.read, read)
                ctx.set(dut.cycle, cycle)

        async def process_loopback(ctx):
            async for output_state in ctx.changed(dut.output_state):
                ctx.set(dut.input_state, output_state[0])

        async def testbench(ctx):
            ctx.set(dut.config.threshold, -10)
            ctx.set(dut.config.holdoff, 32)
            ctx.set(dut.config.postage, 1)

            for v in [-30, -20, -5, -4, 100, -10 - 20, -30, -5]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const({"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}),
                )
                self.assertEqual(ctx.get(dut.dropped), 0)

            for _ in range(33):
                await ctx.tick()

            for v in [-20, -19]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const({"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}),
                )
                if v == -19:
                    self.assertEqual(ctx.get(dut.dropped), 1)
            await ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_process(process_counter)
        sim.add_process(process_loopback)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_trigger1x_drop.vcd"):
            sim.run()


class PostageFIFOTestCase(unittest.TestCase):
    def photons(self, dut, points, extrasets={}):
        channels = dut._count

        async def process(ctx):
            nonlocal points
            i = 0
            async for edge, rst in ctx.tick():
                if rst:
                    i = 0
                elif edge:
                    if i in extrasets.keys():
                        points = extrasets[i]
                    counter = i // channels
                    channel = i % channels
                    ctx.set(
                        dut.postage_stream.payload,
                        dut.postage_stream.payload.shape().const(
                            {
                                "triggered": (channel in points.keys()) and (counter in points[channel]),
                                "iq": iq.from_bits(counter if channel in points.keys() else 0),
                                "bin": channel,
                                "cycle": counter,
                                "read": i // 95,
                            }
                        ),
                    )
                    ctx.set(dut.postage_stream.valid, channel in points.keys())
                    i += 1

        return process

    def nofault(self, dut):
        async def process(ctx):
            async for edge, rst, fault in ctx.tick().sample(dut.fault):
                if edge and not rst:
                    self.assertEqual(fault, 0)

        return process

    def nodrop(self, dut):
        async def process(ctx):
            async for edge, rst, drop in ctx.tick().sample(dut.dropped):
                if edge and not rst:
                    self.assertEqual(drop, 0)

        return process

    def getpackets(self, stream, metadata, packets, meta, ws=0):
        async def process(ctx):
            nonlocal metadata
            ready = True
            waitstate = 0
            ctx.set(stream.ready, ready)
            current_packet = None
            async for edge, rst, valid, payload, m in ctx.tick().sample(
                stream.valid, stream.payload, metadata
            ):
                if edge and valid and not rst and ready:
                    if current_packet is None:
                        current_packet = []
                        meta.append({"bin": int(m.bin), "cycle": int(m.cycle), "read": int(m.read)})
                    current_packet.append((int(payload.iq.real), int(payload.iq.imag)))
                    if payload.last:
                        packets.append(current_packet)
                        current_packet = None
                    if ws:
                        ready, waitstate = False, ws
                elif not ready:
                    if waitstate == 0:
                        ready = True
                    else:
                        waitstate -= 1
                ctx.set(stream.ready, ready)

        return process

    def photon(self, dut, point, bin):
        return list(zip(range(point - dut._before, point - dut._before + dut._length), [0] * dut._length)), {
            "bin": bin,
            "cycle": point,
            "read": ((point * dut._count + bin) // 95) % 4,
        }

    def test_fifo(self):
        dut = PostageFIFO(8, 32, 4)

        os0 = []
        os1 = []
        ms0 = []
        ms1 = []

        async def testbench(ctx):
            for _ in range(16):
                await ctx.tick()
            ctx.set(dut.count, 2)
            while len(os0) == 0 or len(os1) == 0:
                await ctx.tick()
            for _ in range(32 * 4 * 2):
                await ctx.tick()
            self.assertEqual(os0, [self.photon(dut, 32, 0)[0]])
            self.assertEqual(ms0, [self.photon(dut, 32, 0)[1]])
            self.assertEqual(os1, [self.photon(dut, 33, 1)[0]])
            self.assertEqual(ms1, [self.photon(dut, 33, 1)[1]])

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(self.photons(dut, {0: [32, 33], 1: [33, 40]}))
        sim.add_process(self.nofault(dut))
        sim.add_process(self.nodrop(dut))
        sim.add_process(self.getpackets(dut.output_streams[0], dut.output_metadata[0], os0, ms0))
        sim.add_process(self.getpackets(dut.output_streams[1], dut.output_metadata[1], os1, ms1, ws=3))
        with sim.write_vcd("test_postagefifo.vcd"):
            sim.run()

    def test_fifo_drop(self):
        dut = PostageFIFO(8, 32, 4)

        os0 = []
        os1 = []
        os2 = []
        ms0 = []
        ms1 = []
        ms2 = []

        async def testbench(ctx):
            for _ in range(16):
                await ctx.tick()
            ctx.set(dut.count, 3)
            while len(os0) == 0 or len(os1) == 0:
                await ctx.tick()
            for _ in range(32 * 4 * 2):
                await ctx.tick()
            self.assertEqual(list(zip(os0, ms0)), [self.photon(dut, p, 0) for p in [32, 65]])
            self.assertEqual(list(zip(os1, ms1)), [self.photon(dut, 33, 1)])
            self.assertEqual(list(zip(os2, ms2)), [self.photon(dut, p, 2) for p in [32, 65]])
            self.assertEqual(ctx.get(dut.dropped), (1 << 1) | (1 << 2))

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(self.photons(dut, {0: [32, 33, 63, 65], 1: [33, 70], 2: [32, 64, 65]}))
        sim.add_process(self.nofault(dut))
        sim.add_process(self.getpackets(dut.output_streams[0], dut.output_metadata[0], os0, ms0))
        sim.add_process(self.getpackets(dut.output_streams[1], dut.output_metadata[1], os1, ms1, ws=8))
        sim.add_process(self.getpackets(dut.output_streams[2], dut.output_metadata[2], os2, ms2))
        with sim.write_vcd("test_postagefifo_drop.vcd"):
            sim.run()

    def test_fifo_flush(self):
        dut = PostageFIFO(8, 32, 4)

        os0 = []
        os1 = []
        os2 = []
        ms0 = []
        ms1 = []
        ms2 = []

        async def testbench(ctx):
            for _ in range(16):
                await ctx.tick()
            ctx.set(dut.count, 2)
            for _ in range(35 * 4):
                await ctx.tick()
            ctx.set(dut.count, 0)
            while ctx.get(dut.flushed) != 1:
                await ctx.tick()
            self.assertEqual(list(zip(os0, ms0)), [self.photon(dut, p, 0) for p in [32]])
            self.assertEqual(list(zip(os1, ms1)), [self.photon(dut, 33, 1)])
            self.assertEqual(list(zip(os2, ms2)), [])
            while not ((ctx.get(dut.postage_stream.valid) == 1) & (ctx.get(dut.postage_stream.payload.bin) == 2)):
                await ctx.tick()
            ctx.set(dut.count, 3)
            while len(os2) == 0:
                await ctx.tick()
            ctx.set(dut.count, 0)
            while ctx.get(dut.flushed) != 1:
                await ctx.tick()
            self.assertEqual(list(zip(os0, ms0)), [self.photon(dut, p, 0) for p in [32, 1064]])
            self.assertEqual(list(zip(os1, ms1)), [self.photon(dut, 33, 1)])
            self.assertEqual(list(zip(os2, ms2)), [self.photon(dut, 1088, 2)])

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        sim.add_process(
            self.photons(dut, {0: [32, 33, 63], 1: [33, 70]}, extrasets={64*8: {0: [1064], 1: [], 2: [1088]}})
        )
        sim.add_process(self.nofault(dut))
        sim.add_process(self.nodrop(dut))
        sim.add_process(self.getpackets(dut.output_streams[0], dut.output_metadata[0], os0, ms0, ws=4))
        sim.add_process(self.getpackets(dut.output_streams[1], dut.output_metadata[1], os1, ms1, ws=8))
        sim.add_process(self.getpackets(dut.output_streams[2], dut.output_metadata[2], os2, ms2, ws=3))
        with sim.write_vcd("test_postagefifo_flush.vcd"):
            sim.run()
