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
                "iq": data.ArrayLayout(
                    data.StructLayout({"real": signed(16), "imag": signed(16)}), 4
                ),
                "phase": data.ArrayLayout(signed(16), 4),
            }
        ).const(
            {
                "beat": i,
                "iq": data.ArrayLayout(iq, 4).from_bits(
                    sum(
                        [n << (j * 32) for j, n in enumerate(range(i * 4, (i + 1) * 4))]
                    )
                ),
                "phase": data.ArrayLayout(signed(16), 4).from_bits(
                    sum(
                        [n << (j * 16) for j, n in enumerate(range(i * 4, (i + 1) * 4))]
                    )
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
            async for clk_edge, rst, pvalid in ctx.tick().sample(
                dut.postage_stream.valid
            ):
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
                self.assertEqual(
                    ctx.get(dut.output_state.state), TriggerState.State.RESET.value
                )

            for v in [-30, -20, -5, -4, 100, -10]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const(
                        {"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}
                    ),
                )
                self.assertEqual(
                    ctx.get(dut.output_state.state), TriggerState.State.WAITING.value
                )

            for v in [-20, -30, -40, -50, -40, -20]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const(
                        {"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}
                    ),
                )

            self.assertEqual(
                await stream_get(ctx, dut.event_stream),
                trigger_event.const({"phase": -50, "bin": 32, "read": 0, "cycle": 14}),
            )

            for v in [-10, -5, -20, -4, -40, -20, -10]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const(
                        {"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}
                    ),
                )
                self.assertEqual(ctx.get(dut.event_stream.valid), 0)

            for v in range(24):
                self.assertEqual(
                    ctx.get(dut.output_state.state), TriggerState.State.HOLDING.value
                )
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const(
                        {"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}
                    ),
                )

            self.assertEqual(
                ctx.get(dut.output_state.state), TriggerState.State.WAITING.value
            )
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
                    trigger_input.const(
                        {"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}
                    ),
                )
                self.assertEqual(ctx.get(dut.dropped), 0)

            for _ in range(33):
                await ctx.tick()

            for v in [-20, -19]:
                await stream_put_hold(
                    ctx,
                    dut.input_stream,
                    trigger_input.const(
                        {"bin": 32, "iq": {"real": v + 1, "imag": v + 2}, "phase": v}
                    ),
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
    def photons(self, ctx, dut, points, channels):
        i = 0
        async for edge, rst in ctx.tick():
            if rst:
                i = 0
            elif edge:
                counter = i // channels
                channel = i % channels
                ctx.set(
                    dut.postage_stream.payload,
                    dut.postage_stream.payload.shape().const(
                        {
                            "triggered": (channel in points.keys())
                            and (counter in points[channel]),
                            "iq": iq.from_bits(
                                counter if channel in points.keys() else 0
                            ),
                            "bin": channel,
                            "cycle": counter * 8,
                            "read": 1,
                        }
                    )
                )
                ctx.set(dut.postage_stream.valid, channel in points.keys())
                i += 1

    def test_fifo(self, point=12):
        dut = PostageFIFO(8, 32, 4)

        async def testbench(ctx):
            for _ in range(16):
                await ctx.tick()
            ctx.set(dut.count, 2)
            for i in range(64):
                for j in range(6):
                    if j < 2:
                        ctx.set(dut.postage_stream.valid, 1)
                        ctx.set(
                            dut.postage_stream.payload,
                            dut.postage_stream.payload.shape().const(
                                {
                                    "triggered": i == point,
                                    "iq": iq.from_bits(i),
                                    "bin": j,
                                    "cycle": i,
                                    "read": 1,
                                }
                            ),
                        )
                    else:
                        ctx.set(
                            dut.postage_stream.payload,
                            dut.postage_stream.payload.shape().from_bits(0xFFFF_FFFF),
                        )
                        ctx.set(dut.postage_stream.valid, 0)
                    await ctx.tick()
            ch0 = []
            for _ in range(32):
                blah = await stream_get(ctx, dut.output_streams[0])
                ch0.append(blah.iq.real)
            self.assertEqual(
                ch0, list(range(point - dut._before, point - dut._before + dut._length))
            )
            ch1 = []
            for _ in range(32):
                blah = await stream_get(ctx, dut.output_streams[1])
                ch1.append(blah.iq.real)
            self.assertEqual(
                ch1, list(range(point - dut._before, point - dut._before + dut._length))
            )
            for _ in range(16):
                await ctx.tick()

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench)
        with sim.write_vcd("test_postagefifo.vcd"):
            sim.run()
