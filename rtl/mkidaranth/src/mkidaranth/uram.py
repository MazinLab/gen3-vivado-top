from amaranth import *
from amaranth.lib import wiring, memory
from amaranth.vendor import XilinxPlatform

class UltraRAMPort(wiring.Signature):
    def __init__(self):
        super().__init__({
            "addr": wiring.Out(12),
            "en": wiring.Out(1),
            "write": wiring.Out(1),
            "we": wiring.Out(9),

            "dwrite": wiring.Out(72),
            "dread": wiring.In(72),
            "dread_valid": wiring.In(1),

            "sbiterr": wiring.In(1),
            "dbiterr": wiring.In(1),
        })

class UltraRAM(wiring.Component):
    def __init__(self, input_pipeline=True, output_pipeline=True):
        self.input_pipeline = input_pipeline
        self.output_pipeline = output_pipeline
        super().__init__({   
            "a": wiring.In(UltraRAMPort()),
            "b": wiring.In(UltraRAMPort()),
            "sleep": wiring.In(1),
        })

    def elaborate(self, platform):
        m = Module()

        assert isinstance(platform, XilinxPlatform) or (platform is None), "Platform must be sim or Xilinx"

        if isinstance(platform, XilinxPlatform):
            m.submodules.uram = Instance("URAM288E5",
                i_CLK=ClockSignal(),
                i_SLEEP=self.sleep,
                i_ADDR_A=self.a.addr,
                i_EN_A=self.a.en,
                i_RDB_WR_A=self.a.write,
                i_BWE_A=self.a.we,
                i_DIN_A=self.a.dwrite,
                i_INJECT_SBITERR_A=Const(0),
                i_INJECT_DBITERR_A=Const(0),
                i_OREG_CE_A=Const(1),
                i_OREG_ECC_CE_A=Const(1),
                i_RST_A=ResetSignal(),
                o_DOUT_A=self.a.dread,
                o_RDACCESS_A=self.a.dread_valid,
                o_SBITERR_A=self.a.sbiterr,
                o_DBITERR_A=self.a.dbiterr,
                i_ADDR_B=self.b.addr,
                i_EN_B=self.b.en,
                i_RDB_WR_B=self.b.write,
                i_BWE_B=self.b.we,
                i_DIN_B=self.b.dwrite,
                i_INJECT_SBITERR_B=Const(0),
                i_INJECT_DBITERR_B=Const(0),
                i_OREG_CE_B=Const(1),
                i_OREG_ECC_CE_B=Const(1),
                i_RST_B=ResetSignal(),
                o_DOUT_B=self.b.dread,
                o_RDACCESS_B=self.b.dread_valid,
                o_SBITERR_B=self.b.sbiterr,
                o_DBITERR_B=self.b.dbiterr,
                p_BWE_MODE_A="PARITY_INDEPENDENT",
                p_BWE_MODE_B="PARITY_INDEPENDENT",
                p_OREG_A="TRUE" if self.output_pipeline else "FALSE",
                p_OREG_B="TRUE" if self.output_pipeline else "FALSE",
                p_OREG_ECC_A="TRUE" if self.output_pipeline else "FALSE",
                p_OREG_ECC_B="TRUE" if self.output_pipeline else "FALSE",
                p_IREG_PRE_A="TRUE" if self.input_pipeline else "FALSE",
                p_IREG_PRE_B="TRUE" if self.input_pipeline else "FALSE",
            )
        elif platform is None:
            m.submodules.sim_uram = sim_uram = memory.Memory(shape=unsigned(72), depth=1024*4, init=[])
            ra = sim_uram.read_port(domain="sync")
            wa = sim_uram.write_port(granularity=8)
            rb = sim_uram.read_port(domain="sync", transparent_for=(wa,))
            wb = sim_uram.write_port(granularity=8)

            arvi = Signal()
            arvm = Signal()
            brvi = Signal()
            brvm = Signal()

            input_assignments_a = [
                ra.addr.eq(self.a.addr),
                wa.addr.eq(self.a.addr),
                ra.en.eq(self.a.en & ~self.a.write),
                wa.en.eq(Mux(self.a.en & self.a.write, self.a.we, 0)),
                wa.data.eq(self.a.dwrite),
                arvi.eq(ra.en & ~self.a.write),
            ]
            output_assignments_a = [
                self.a.dread.eq(ra.data),
                self.a.dread_valid.eq(arvm)
            ]
            m.d.sync += arvm.eq(arvi)
            if self.input_pipeline:
                m.d.sync += input_assignments_a
            else:
                m.d.comb += input_assignments_a
            if self.output_pipeline:
                m.d.sync += output_assignments_a
            else:
                m.d.comb += output_assignments_a

            input_assignments_b = [
                rb.addr.eq(self.b.addr),
                wb.addr.eq(self.b.addr),
                rb.en.eq(self.b.en & ~self.b.write),
                wb.en.eq(Mux(self.b.en & self.b.write, self.b.we, 0)),
                wb.data.eq(self.b.dwrite),
                brvi.eq(rb.en & ~self.b.write),
            ]
            output_assignments_b = [
                self.b.dread.eq(rb.data),
                self.b.dread_valid.eq(brvm)
            ]
            m.d.sync += brvm.eq(brvi)
            if self.input_pipeline:
                m.d.sync += input_assignments_b
            else:
                m.d.comb += input_assignments_b
            if self.output_pipeline:
                m.d.sync += output_assignments_b
            else:
                m.d.comb += output_assignments_b
            
            with m.If((self.a.addr == self.b.addr) & self.a.write & self.b.write & self.a.en & self.b.en):
                if self.input_pipeline:
                    m.d.sync += wa.en.eq(self.a.we & (~self.b.we))
                else:
                    m.d.comb += wa.en.eq(self.a.we & (~self.b.we))
                    
        return m

if __name__ == "__main__":
    from amaranth.sim import Simulator
    from amaranth.back import verilog
    from amaranth.vendor import XilinxPlatform

    class RFSoCGen3Platform(XilinxPlatform):
        device = "xczu48dr"
        package = "ffvg1517"
        speed = "2"
        resources = []
        connectors = []

    verilog.convert(UltraRAM(True, True))
    verilog.convert(UltraRAM(True, False))
    verilog.convert(UltraRAM(False, True))
    verilog.convert(UltraRAM(False, False))

    print(verilog.convert(UltraRAM(), platform=RFSoCGen3Platform()))

    dut = UltraRAM()
    async def testbench(ctx):
        ctx.set(dut.a.en, 1)
        for i in range(32):
            ctx.set(dut.a.addr, i)
            await ctx.tick()

    sim = Simulator(dut)
    sim.add_clock(1e-6)
    sim.add_testbench(testbench)
    with sim.write_vcd("test_uram_latency.vcd"):
        sim.run()
