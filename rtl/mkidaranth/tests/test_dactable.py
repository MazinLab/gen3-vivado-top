import unittest

from amaranth import *
from amaranth.lib import wiring, stream, data
from amaranth.sim import Simulator

from mkidaranth.dactable import Table


async def stream_put(ctx, stream, payload, *, context=None):
    ctx.set(stream.payload, payload)
    ctx.set(stream.valid, 1)
    await ctx.tick(context=context).until(stream.ready)
    ctx.set(stream.valid, 0)


async def stream_get(ctx, stream, *, context=None):
    if not isinstance(stream.ready, Const):
        ctx.set(stream.ready, 1)
    payload, = await ctx.tick(context=context).sample(stream.payload).until(stream.valid)
    if not isinstance(stream.ready, Const):
        ctx.set(stream.ready, 0)
    return payload


async def stream_assert(ctx, stream, expected, msg=""):
    value = await stream_get(ctx, stream)
    for key, expected_value in expected.items():
        assert value[key] == expected_value, \
            f"payload.{key}: {value[key]!r} != {expected_value!r} {msg}"


async def dactable_write(ctx, table, address, data, *, context=None):
    ctx.set(table.waddr, address)
    ctx.set(table.wdata, data)
    ctx.set(table.wen, 1)
    await ctx.tick(context=context)
    ctx.set(table.wen, 0)


def init(dut):
    async def testbench_init(ctx):
        for s in range(4):
            for c in range(4):
                for r in range(4):
                    d = dut._subtables[s]._rams[c]._urams[r]._sim_uram.data
                    for i in range(4096):
                        p = s
                        ctx.set(d[i], p | p << 16 | p << 32 | p << 48 | p << 64)

    return testbench_init


class TableTestCase(unittest.TestCase):
    def test_write(self):
        import random
        random.seed(4)
        nums = [int.from_bytes(random.randbytes(256//8)) for _ in range(8192)]

        dut = Table()

        async def testbench_write(ctx):
            for i, num in enumerate(nums):
                await dactable_write(ctx, dut, i, num)
            await ctx.tick().repeat(16)
            ctx.set(dut.enable, 1)

        async def testbench_read(ctx):
            for i, n in enumerate(nums):
                def _signed(p):
                    return int.from_bytes(int.to_bytes(p, 2, 'little'), 'little', signed=True)
                await stream_assert(ctx, dut.o, {
                    "i": [_signed((n >> i)         & 0xffff) for i in range(0, 128, 16)],
                    "q": [_signed((n >> (i + 128)) & 0xffff) for i in range(0, 128, 16)],
                    "id": i // (4096 * 4),
                    "last": i % (4096 * 4) == (4096 * 4 - 1)
                })

        sim = Simulator(dut)
        sim.add_clock(1e-6)
        sim.add_testbench(testbench_write)
        sim.add_testbench(testbench_read)

        sim.run()

    @unittest.skip("Fucking slow")
    def test_table(self):
        dut = Table()

        async def testbench_output(ctx):
            for s in range(4):
                for i in range(4096 * 4):
                    await stream_assert(ctx, dut.o, {
                        "i": [s for _ in range(8)],
                        "q": [s for _ in range(8)],
                        "id": s,
                        "last": i == 4096 * 4 - 1
                    })

        async def testbench_input(ctx):
            for _ in range(32):
                await ctx.tick()
            ctx.set(dut.mask, 0b11)
            ctx.set(dut.enable, 1)

        sim = Simulator(dut)
        sim.add_clock(1e-6)

        sim.add_testbench(init(dut))
        sim.add_testbench(testbench_output)
        sim.add_testbench(testbench_input)

        sim.run()

    @unittest.skip("Fucking slow")
    def test_mask(self):
        dut = Table()

        async def testbench_output(ctx):
            for s in range(4):
                for i in range(4096 * 4):
                    await stream_assert(ctx, dut.o, {
                        "i": [s & 0b01 | 0b10 for _ in range(8)],
                        "q": [s & 0b01 | 0b10 for _ in range(8)],
                        "id": s & 0b01 | 0b10,
                        "last": i == 4096 * 4 - 1
                    })

        async def testbench_input(ctx):
            for _ in range(32):
                await ctx.tick()
            ctx.set(dut.mask,   0b01)
            ctx.set(dut.select, 0b10)
            ctx.set(dut.enable, 1)

        sim = Simulator(dut)
        sim.add_clock(1e-6)

        sim.add_testbench(init(dut))
        sim.add_testbench(testbench_output)
        sim.add_testbench(testbench_input)

        sim.run()
