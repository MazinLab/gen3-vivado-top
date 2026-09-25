from amaranth import *
from amaranth.utils import ceil_log2
from amaranth.lib import wiring, memory, enum
from amaranth.vendor import XilinxPlatform


class UltraRAMPort(wiring.Signature):
    def __init__(self):
        super().__init__({
            "addr": wiring.Out(23),
            "en": wiring.Out(1),
            "wr": wiring.Out(1),
            "we": wiring.Out(9),

            "data_write": wiring.Out(72),
            "data_read": wiring.In(72),
            "data_read_valid": wiring.In(1),

            "single_biterror": wiring.In(1),
            "double_biterror": wiring.In(1),
        })


class UltraRAMCascadePort(wiring.Signature):
    def __init__(self):
        super().__init__({
            "addr": wiring.Out(23),
            "en": wiring.Out(1),
            "wr": wiring.Out(1),
            "we": wiring.Out(9),

            "data_write": wiring.Out(72),
            "data_read": wiring.Out(72),
            "data_read_valid": wiring.Out(1),

            "single_biterror": wiring.Out(1),
            "double_biterror": wiring.Out(1),
        })


class UltraRAMCascadeMode(enum.Enum):
    NONE   = "NONE"
    FIRST  = "FIRST"
    MIDDLE = "MIDDLE"
    LAST   = "LAST"


class UltraRAM(wiring.Component):
    def __init__(
        self, *,
        input_pipeline=True, output_pipeline=True, ecc_pipeline=False, cascade_pipeline=False,
        cascade_mode_a=UltraRAMCascadeMode.NONE, cascade_mode_b=UltraRAMCascadeMode.NONE,
        self_addr_a = 0x000, self_addr_b = 0x000, self_mask_a = 0x7ff, self_mask_b = 0x7ff
    ):
        self.input_pipeline = input_pipeline
        self.output_pipeline = output_pipeline
        self.ecc_pipeline = ecc_pipeline
        self.cascade_pipeline = cascade_pipeline

        self.cascade_mode_a = cascade_mode_a
        self.cascade_mode_b = cascade_mode_b

        self.self_addr_a = self_addr_a
        self.self_addr_b = self_addr_b
        self.self_mask_a = self_mask_a
        self.self_mask_b = self_mask_b

        self._test_init = None

        super().__init__({
            "a": wiring.In(UltraRAMPort()),
            "b": wiring.In(UltraRAMPort()),
            "a_cascade_out": wiring.Out(UltraRAMCascadePort()),
            "b_cascade_out": wiring.Out(UltraRAMCascadePort()),
            "a_cascade_in": wiring.In(UltraRAMCascadePort()),
            "b_cascade_in": wiring.In(UltraRAMCascadePort()),
            "sleep": wiring.In(1),
        })

    def elaborate(self, platform):
        m = Module()

        assert isinstance(platform, XilinxPlatform) or (platform is None), "Platform must be sim or Xilinx"

        if isinstance(platform, XilinxPlatform):
            m.submodules.uram = Instance("URAM288",
                i_CLK=ClockSignal(),
                i_SLEEP=self.sleep,

                # A
                i_ADDR_A=self.a.addr,
                i_EN_A=self.a.en,
                i_RDB_WR_A=self.a.wr,
                i_BWE_A=self.a.we,
                i_DIN_A=self.a.data_write,
                i_INJECT_SBITERR_A=Const(0),
                i_INJECT_DBITERR_A=Const(0),
                i_OREG_CE_A=Const(1),
                i_OREG_ECC_CE_A=Const(1),
                i_RST_A=ResetSignal(),
                o_DOUT_A=self.a.data_read,
                o_RDACCESS_A=self.a.data_read_valid,
                o_SBITERR_A=self.a.single_biterror,
                o_DBITERR_A=self.a.double_biterror,

                # B
                i_ADDR_B=self.b.addr,
                i_EN_B=self.b.en,
                i_RDB_WR_B=self.b.wr,
                i_BWE_B=self.b.we,
                i_DIN_B=self.b.data_write,
                i_INJECT_SBITERR_B=Const(0),
                i_INJECT_DBITERR_B=Const(0),
                i_OREG_CE_B=Const(1),
                i_OREG_ECC_CE_B=Const(1),
                i_RST_B=ResetSignal(),
                o_DOUT_B=self.b.data_read,
                o_RDACCESS_B=self.b.data_read_valid,
                o_SBITERR_B=self.b.single_biterror,
                o_DBITERR_B=self.b.double_biterror,

                # CASIN A
                i_CAS_IN_ADDR_A=self.a_cascade_in.addr,
                i_CAS_IN_EN_A=self.a_cascade_in.en,
                i_CAS_IN_RDB_WR_A=self.a_cascade_in.wr,
                i_CAS_IN_BWE_A=self.a_cascade_in.we,
                i_CAS_IN_DIN_A=self.a_cascade_in.data_write,
                i_CAS_IN_DOUT_A=self.a_cascade_in.data_read,
                i_CAS_IN_RDACCESS_A=self.a_cascade_in.data_read_valid,
                i_CAS_IN_SBITERR_A=self.a_cascade_in.single_biterror,
                i_CAS_IN_DBITERR_A=self.a_cascade_in.double_biterror,

                # CASIN B
                i_CAS_IN_ADDR_B=self.b_cascade_in.addr,
                i_CAS_IN_EN_B=self.b_cascade_in.en,
                i_CAS_IN_RDB_WR_B=self.b_cascade_in.wr,
                i_CAS_IN_BWE_B=self.b_cascade_in.we,
                i_CAS_IN_DIN_B=self.b_cascade_in.data_write,
                i_CAS_IN_DOUT_B=self.b_cascade_in.data_read,
                i_CAS_IN_RDACCESS_B=self.b_cascade_in.data_read_valid,
                i_CAS_IN_SBITERR_B=self.b_cascade_in.single_biterror,
                i_CAS_IN_DBITERR_B=self.b_cascade_in.double_biterror,

                # CASOUT A
                o_CAS_OUT_ADDR_A=self.a_cascade_out.addr,
                o_CAS_OUT_EN_A=self.a_cascade_out.en,
                o_CAS_OUT_RDB_WR_A=self.a_cascade_out.wr,
                o_CAS_OUT_BWE_A=self.a_cascade_out.we,
                o_CAS_OUT_DIN_A=self.a_cascade_out.data_write,
                o_CAS_OUT_DOUT_A=self.a_cascade_out.data_read,
                o_CAS_OUT_RDACCESS_A=self.a_cascade_out.data_read_valid,
                o_CAS_OUT_SBITERR_A=self.a_cascade_out.single_biterror,
                o_CAS_OUT_DBITERR_A=self.a_cascade_out.double_biterror,

                # CASOUT B
                o_CAS_OUT_ADDR_B=self.b_cascade_out.addr,
                o_CAS_OUT_EN_B=self.b_cascade_out.en,
                o_CAS_OUT_RDB_WR_B=self.b_cascade_out.wr,
                o_CAS_OUT_BWE_B=self.b_cascade_out.we,
                o_CAS_OUT_DIN_B=self.b_cascade_out.data_write,
                o_CAS_OUT_DOUT_B=self.b_cascade_out.data_read,
                o_CAS_OUT_RDACCESS_B=self.b_cascade_out.data_read_valid,
                o_CAS_OUT_SBITERR_B=self.b_cascade_out.single_biterror,
                o_CAS_OUT_DBITERR_B=self.b_cascade_out.double_biterror,

                # WE Mode
                p_BWE_MODE_A="PARITY_INDEPENDENT",
                p_BWE_MODE_B="PARITY_INDEPENDENT",

                # Pipeline Registers
                p_OREG_A="TRUE" if self.output_pipeline else "FALSE",
                p_OREG_B="TRUE" if self.output_pipeline else "FALSE",
                p_OREG_ECC_A="TRUE" if self.ecc_pipeline else "FALSE",
                p_OREG_ECC_B="TRUE" if self.ecc_pipeline else "FALSE",
                p_IREG_PRE_A="TRUE" if self.input_pipeline else "FALSE",
                p_IREG_PRE_B="TRUE" if self.input_pipeline else "FALSE",

                # Cascade Parameters
                p_CASCADE_ORDER_A=self.cascade_mode_a.value,
                p_CASCADE_ORDER_B=self.cascade_mode_b.value,
                p_SELF_ADDR_A=self.self_addr_a,
                p_SELF_ADDR_B=self.self_addr_b,
                p_SELF_MASK_A=self.self_mask_a,
                p_SELF_MASK_B=self.self_mask_b,
            )
        elif platform is None:
            self._sim_uram = m.submodules.sim_uram = sim_uram = \
                memory.Memory(shape=unsigned(72), depth=1024*4, init=self._test_init if self._test_init else [])

            ra = sim_uram.read_port(domain="sync")
            wa = sim_uram.write_port(granularity=8)
            rb = sim_uram.read_port(domain="sync", transparent_for=(wa,))
            wb = sim_uram.write_port(granularity=8)

            def address_match(address, address_mask, address_self):
                amatch = (~(address_self ^ address.shift_right(12)) | address_mask) == 0x7ff
                return amatch

            for ports in [
                (self.a, self.a_cascade_out, self.a_cascade_in, ra, wa, self.self_addr_a, self.self_mask_a),
                (self.b, self.b_cascade_out, self.b_cascade_in, rb, wb, self.self_addr_b, self.self_mask_b),
            ]:
                port, caso, casi, rp, wp, self_addr, self_mask = ports[0], ports[1], ports[2], ports[3], ports[4], ports[5], ports[6]

                read_valid_pipe = Signal()

                match self.cascade_mode_a:
                    case UltraRAMCascadeMode.NONE:
                        ip = port
                    case UltraRAMCascadeMode.FIRST:
                        ip = port
                    case UltraRAMCascadeMode.MIDDLE:
                        ip = casi
                    case UltraRAMCascadeMode.LAST:
                        ip = casi

                # Input Control Path
                ir_addr       = Signal.like(port.addr)
                ir_en         = Signal.like(port.en)
                ir_wr         = Signal.like(port.wr)
                ir_we         = Signal.like(port.we)
                ir_data_write = Signal.like(port.data_write)

                input_assignments = [
                    ir_addr      .eq(ip.addr),
                    ir_en        .eq(ip.en),
                    ir_wr        .eq(ip.wr),
                    ir_we        .eq(ip.we),
                    ir_data_write.eq(ip.data_write),
                ]

                if ip == port and self.input_pipeline:
                    m.d.sync += input_assignments
                elif ip == port:
                    m.d.comb += input_assignments
                elif self.cascade_pipeline:
                    m.d.sync += input_assignments
                else:
                    m.d.comb += input_assignments

                match = Signal(1)
                m.d.comb += match.eq(address_match(ir_addr, self_mask, self_addr))
                read_this_ram = match & ir_en & ~ir_wr
                m.d.sync += [
                    read_valid_pipe.eq(read_this_ram)
                ]

                m.d.comb += [
                    wp.en.eq(ir_we & (match & ir_en & ir_wr).replicate(len(ir_we))),
                    wp.data.eq(ir_data_write),
                    wp.addr.eq(ir_addr),
                    rp.en.eq(read_this_ram),
                    rp.addr.eq(ir_addr),
                ]

                m.d.comb += [
                    caso.addr      .eq(ir_addr),
                    caso.en        .eq(ir_en),
                    caso.wr        .eq(ir_wr),
                    caso.we        .eq(ir_we),
                    caso.data_write.eq(ir_data_write),
                ]

                # Output Data Reg
                or_data_read       = Signal.like(port.data_read)
                or_data_read_valid = Signal.like(port.data_read_valid)
                or_single_biterror = Signal.like(port.single_biterror)
                or_double_biterror = Signal.like(port.double_biterror)
                oreg_assignments = [
                    or_data_read.eq(rp.data),
                    or_data_read_valid.eq(read_valid_pipe),
                    or_single_biterror.eq(0),
                    or_double_biterror.eq(0),
                ]
                if self.output_pipeline:
                    m.d.sync += oreg_assignments
                else:
                    m.d.comb += oreg_assignments

                # Output ECC path
                or_ecc_data_read       = Signal.like(port.data_read)
                or_ecc_data_read_valid = Signal.like(port.data_read_valid)
                or_ecc_single_biterror = Signal.like(port.single_biterror)
                or_ecc_double_biterror = Signal.like(port.double_biterror)
                ecc_assignments = [
                    or_ecc_data_read.eq(or_data_read),
                    or_ecc_data_read_valid.eq(or_data_read_valid),
                    or_ecc_single_biterror.eq(or_single_biterror),
                    or_ecc_double_biterror.eq(or_double_biterror),
                ]
                if self.ecc_pipeline:
                    m.d.sync += ecc_assignments
                else:
                    m.d.comb += ecc_assignments

                # Output cascade path
                or_cas_data_read       = Signal.like(port.data_read)
                or_cas_data_read_valid = Signal.like(port.data_read_valid)
                or_cas_single_biterror = Signal.like(port.single_biterror)
                or_cas_double_biterror = Signal.like(port.double_biterror)
                cas_assignments = [
                    or_cas_data_read.eq(casi.data_read),
                    or_cas_data_read_valid.eq(casi.data_read_valid),
                    or_cas_single_biterror.eq(casi.single_biterror),
                    or_cas_double_biterror.eq(casi.double_biterror),
                ]
                if self.cascade_pipeline:
                    m.d.sync += cas_assignments
                else:
                    m.d.comb += cas_assignments

                m.d.comb += [
                    port.data_read      .eq(or_ecc_data_read),
                    port.data_read_valid.eq(or_ecc_data_read_valid),
                    port.single_biterror.eq(or_ecc_single_biterror),
                    port.double_biterror.eq(or_ecc_double_biterror),
                ]
                with m.If(or_cas_data_read_valid):
                    m.d.comb += [
                        port.data_read_valid.eq(or_cas_data_read_valid),
                        port.data_read.eq(or_cas_data_read),
                        port.single_biterror.eq(or_cas_single_biterror),
                        port.double_biterror.eq(or_cas_single_biterror),
                    ]
                m.d.comb += [
                    caso.data_read_valid.eq(port.data_read_valid),
                    caso.data_read.eq(port.data_read),
                    caso.single_biterror.eq(port.single_biterror),
                    caso.double_biterror.eq(port.double_biterror),
                ]

        return m

class UltraRAMColumn(wiring.Component):
    def __init__(self, count):
        assert (1 << count) - 1 < 0x7ff
        self._count = count
        self._mask = 0x7ff ^ ((1 << ceil_log2(count)) - 1)

        def mode(i):
            if i == 0:
                return UltraRAMCascadeMode.FIRST
            if i == count - 1:
                return UltraRAMCascadeMode.LAST
            return UltraRAMCascadeMode.MIDDLE

        self._urams = [
            UltraRAM(
                input_pipeline=True, output_pipeline=True, cascade_pipeline=True,
                self_addr_a=i, self_addr_b=i, self_mask_a=self._mask, self_mask_b=self._mask,
                cascade_mode_a=mode(i), cascade_mode_b=mode(i)
            )
            for i in range(count)
        ]

        super().__init__({
            "a": wiring.In(UltraRAMPort()),
            "b": wiring.In(UltraRAMPort()),
        })

    def elaborate(self, platform):
        m = Module()

        for i, u in enumerate(self._urams):
            m.submodules[f"uram{i}"] = u

        for i in range(1, len(self._urams)):
            wiring.connect(m, self._urams[i-1].a_cascade_out, self._urams[i].a_cascade_in)
            wiring.connect(m, self._urams[i-1].b_cascade_out, self._urams[i].b_cascade_in)

        su = self._urams[+0]
        eu = self._urams[-1]
        wiring.connect(m, wiring.flipped(self.a), su.a)
        wiring.connect(m, wiring.flipped(self.b), su.b)
        m.d.comb += [
            self.a.data_read      .eq(eu.a.data_read),
            self.a.data_read_valid.eq(eu.a.data_read_valid),
            self.a.single_biterror.eq(eu.a.single_biterror),
            self.b.data_read      .eq(eu.b.data_read),
            self.b.data_read_valid.eq(eu.b.data_read_valid),
            self.b.single_biterror.eq(eu.b.single_biterror),
        ]

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

    # dut = UltraRAM()
    dut = UltraRAMColumn(4)
    for i in range(4):
        dut._urams[i]._test_init = [i * 4096 + j for j in range(4096)]
    async def testbench(ctx):
        ctx.set(dut.a.en, 1)
        for j in range(0, 4096 * 4, 4096):
            for i in range(32):
                ctx.set(dut.a.addr, i + j)
                await ctx.tick()

    sim = Simulator(dut)
    sim.add_clock(1e-6)
    sim.add_testbench(testbench)
    with sim.write_vcd("test_uram_latency.vcd"):
        sim.run()
