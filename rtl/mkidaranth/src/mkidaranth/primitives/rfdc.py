from amaranth import *
from amaranth.lib import wiring, enum, data
from amaranth.vendor import XilinxPlatform


class RFDCTileUSP(enum.Enum):
    ADC_224 = (224, "RFADC_X0Y0")
    ADC_225 = (225, "RFADC_X0Y1")
    ADC_226 = (226, "RFADC_X0Y2")
    ADC_227 = (227, "RFADC_X0Y3")
    DAC_228 = (228, "RFDAC_X0Y0")
    DAC_229 = (229, "RFDAC_X0Y1")
    DAC_230 = (230, "RFDAC_X0Y2")
    DAC_231 = (231, "RFDAC_X0Y3")


class DRPort(wiring.Signature):
    def __init__(self, address_width):
        super().__init__({
            "addr": wiring.Out(address_width),
            "en": wiring.Out(1),
            "we": wiring.Out(1),
            "rdy": wiring.In(1),
            "i": wiring.Out(16),
            "out": wiring.In(16),
        })


class RFDCClockCascade(wiring.Signature):
    def __init__(self, *, t1_allowed: bool = False, clkdist: bool = True):
        members = {
            "sysref": wiring.Out(1),
        }
        if clkdist:
            members["clkdist"] = wiring.Out(1)
        if t1_allowed:
            members["t1_allowed"] = wiring.Out(1)

        super().__init__(members)


class DACCommonStatus(data.Struct):
    unk0:    2  # bit [0-1]
    powerup: 1  # bit 2
    unk1:    5  # bit [3-7]
    sysref:  1  # bit 8
    unk2:    15 # bit [9-23]

class DACStatus(data.Struct):
    unk0: 24

class DACCommonCtrl(data.Struct):
    unk0: 16

class DACCtrl(data.Struct):
    unk0: 16

class RFDAC(wiring.Component):
    def __init__(self, tile, *,
        dacclk_domain, pllref_domain="sync", drp_domain="sync",
        fabric_domain="sync", pllmon_domain="sync"
    ):
        assert tile in [RFDCTileUSP.DAC_228, RFDCTileUSP.DAC_229, RFDCTileUSP.DAC_230, RFDCTileUSP.DAC_231]
        self._tile = tile

        self._dacclk_domain = dacclk_domain
        self._pllref_domain = pllref_domain
        self._drp_domain = drp_domain
        self._fabric_domain = fabric_domain
        self._pllmon_domain = pllmon_domain

        members = {
            # T1 clocks can only be cascaded in one direction (TODO: check which one)
            "o_dist_north": wiring.Out(RFDCClockCascade()),
            "o_dist_south": wiring.Out(RFDCClockCascade(t1_allowed=True)),
            "i_dist_south": wiring.In(RFDCClockCascade(clkdist=tile != RFDCTileUSP.DAC_228)),

            "drp": wiring.In(DRPort(12)),
            "control_common": wiring.In(DACCommonCtrl),
            "status_common": wiring.Out(DACCommonStatus),

            "control": wiring.In(DACCtrl).array(4),
            "status": wiring.Out(DACStatus).array(4),

            "samples": wiring.In(signed(16)).array(16).array(4)
        }
        if tile != RFDCTileUSP.DAC_231:
            members["i_dist_north"] = wiring.In(RFDCClockCascade(t1_allowed=True))

        super().__init__(members)

    def elaborate(self, platform):
        m = Module()
        kwargs = {}
        for i in range(4):
            kwargs[f"o_STATUS_DAC{i}"] = self.status[i]
            kwargs[f"i_CONTROL_DAC{i}"] = self.control[i]
            kwargs[f"i_DATA_DAC{i}"] = Cat(*self.samples[i])

        if self._tile != RFDCTileUSP.DAC_231:
            kwargs["i_T1_ALLOWED_NORTH"] = self.i_dist_north.t1_allowed
            kwargs["i_SYSREF_IN_NORTH"] = self.i_dist_north.sysref
            kwargs["i_CLK_DIST_IN_NORTH"] = self.i_dist_north.clkdist

        if self._tile != RFDCTileUSP.DAC_228:
            kwargs["i_CLK_DIST_IN_SOUTH"] = self.i_dist_south.clkdist

        m.submodules.dac = dac = Instance("RFDAC",
            p_OPT_CLK_DIST=self._tile.value[0],

            # Common Control
            i_CONTROL_COMMON=self.control_common,

            # Distribution Outputs
            o_SYSREF_OUT_NORTH=self.o_dist_north.sysref,
            o_CLK_DIST_OUT_NORTH=self.o_dist_north.clkdist,
            o_SYSREF_OUT_SOUTH=self.o_dist_south.sysref,
            o_CLK_DIST_OUT_SOUTH=self.o_dist_south.clkdist,
            o_T1_ALLOWED_SOUTH=self.o_dist_south.t1_allowed,

            # Distribution Inputs
            i_SYSREF_IN_SOUTH=self.i_dist_south.sysref,

            # DRP
            i_DADDR=self.drp.addr,
            i_DEN=self.drp.en,
            i_DWE=self.drp.we,
            i_DI=self.drp.i,
            o_DOUT=self.drp.out,
            o_DRDY=self.drp.rdy,

            # Clocking
            i_DCLK=ClockSignal(self._drp_domain),
            i_FABRIC_CLK=ClockSignal(self._fabric_domain),
            i_PLL_MONCLK=ClockSignal(self._pllmon_domain),
            i_PLL_REFCLK_IN=ClockSignal(self._pllref_domain),

            # Do we need these ??
            o_CLK_DAC=Signal(1),

            # DAC Specific Signals
            **kwargs
        )
        dac.attrs["LOC"] = self._tile.value[1]
        dac.attrs["DONT_TOUCH"] = "TRUE"
        return m

class ADCCommonStatus(data.Struct):
    unk0: 24

class ADCStatus(data.Struct):
    unk0: 24

class ADCCommonCtrl(data.Struct):
    unk0: 16

class ADCCtrl(data.Struct):
    unk0: 16

class RFADC(wiring.Component):
    def __init__(self, tile, *,
        adcclk_domain, pllref_domain="sync", drp_domain="sync",
        fabric_domain="sync", pllmon_domain="sync"
    ):
        assert tile in [RFDCTileUSP.ADC_224, RFDCTileUSP.ADC_225, RFDCTileUSP.ADC_226, RFDCTileUSP.ADC_227]
        self._tile = tile

        self._adcclk_domain = adcclk_domain
        self._pllref_domain = pllref_domain
        self._drp_domain = drp_domain
        self._fabric_domain = fabric_domain
        self._pllmon_domain = pllmon_domain

        members = {
            # T1 clocks can only be cascaded in one direction (TODO: check which one)
            "o_dist_north": wiring.Out(RFDCClockCascade(clkdist=tile != RFDCTileUSP.ADC_227)),
            "i_dist_north": wiring.In(RFDCClockCascade(t1_allowed=True)),
            "o_dist_south": wiring.Out(RFDCClockCascade(t1_allowed=True)),

            "drp": wiring.In(DRPort(12)),
            "control_common": wiring.In(ADCCommonCtrl),
            "status_common": wiring.Out(DACCommonStatus),

            "control": wiring.In(ADCCtrl).array(4),
            "status": wiring.Out(ADCStatus).array(4),

            "samples": wiring.Out(signed(12)).array(16).array(4)
        }

        if tile != RFDCTileUSP.ADC_224:
            members["i_dist_south"] = wiring.In(RFDCClockCascade())

        super().__init__(members)

    def elaborate(self, platform):
        m = Module()
        kwargs = {}
        for i in range(4):
            kwargs[f"o_STATUS_ADC{i}"] = self.status[i]
            kwargs[f"i_CONTROL_ADC{i}"] = self.control[i]
            kwargs[f"o_DATA_ADC{i}"] = Cat(*self.samples[i])

        if self._tile != RFDCTileUSP.ADC_224:
            kwargs["i_SYSREF_IN_SOUTH"] = self.i_dist_south.sysref
            kwargs["i_CLK_DIST_IN_SOUTH"] = self.i_dist_south.clkdist

        if self._tile != RFDCTileUSP.ADC_227:
            kwargs["o_CLK_DIST_OUT_NORTH"] = self.o_dist_north.clkdist

        m.submodules.adc = adc = Instance("RFADC",
            p_OPT_CLK_DIST=self._tile.value[0],

            # Common Control
            i_CONTROL_COMMON=self.control_common,

            # Distribution Outputs
            o_SYSREF_OUT_NORTH=self.o_dist_north.sysref,
            o_SYSREF_OUT_SOUTH=self.o_dist_south.sysref,
            o_CLK_DIST_OUT_SOUTH=self.o_dist_south.clkdist,
            o_T1_ALLOWED_SOUTH=self.o_dist_south.t1_allowed,

            # Distribution Inputs
            i_SYSREF_IN_NORTH=self.i_dist_north.sysref,
            i_CLK_DIST_IN_NORTH=self.i_dist_north.clkdist,
            i_T1_ALLOWED_NORTH=self.i_dist_north.t1_allowed,

            # DRP
            i_DADDR=self.drp.addr,
            i_DEN=self.drp.en,
            i_DWE=self.drp.we,
            i_DI=self.drp.i,
            o_DOUT=self.drp.out,
            o_DRDY=self.drp.rdy,

            # Clocking
            i_DCLK=ClockSignal(self._drp_domain),
            i_FABRIC_CLK=ClockSignal(self._fabric_domain),
            i_PLL_MONCLK=ClockSignal(self._pllmon_domain),
            i_PLL_REFCLK_IN=ClockSignal(self._pllref_domain),

            # Do we need these ??
            o_CLK_ADC=Signal(1),

            **kwargs
        )
        adc.attrs["LOC"] = self._tile.value[1]
        adc.attrs["DONT_TOUCH"] = "TRUE"
        return m

class RFDCTilesUSP(wiring.Component):
    adc_samples: wiring.Out(signed(16)).array(12).array(4).array(4)
    dac_samples: wiring.In(signed(16)).array(16).array(4).array(4)

    def elaborate(self, platform):
        m = Module()
        tiles = []
        adcs = []
        dacs = []

        for adc_tile in [RFDCTileUSP.ADC_224, RFDCTileUSP.ADC_225, RFDCTileUSP.ADC_226, RFDCTileUSP.ADC_227]:
            m.submodules[f"adc{adc_tile.value[0]}"] = adc = RFADC(adc_tile, adcclk_domain="sync")
            tiles.append(adc)
            adcs.append(adc)

        for dac_tile in [RFDCTileUSP.DAC_228, RFDCTileUSP.DAC_229, RFDCTileUSP.DAC_230, RFDCTileUSP.DAC_231]:
            m.submodules[f"dac{dac_tile.value[0]}"] = dac = RFDAC(dac_tile, dacclk_domain="sync")
            tiles.append(dac)
            dacs.append(dac)

        for i in range(len(tiles) - 1, 0, -1):
            wiring.connect(m, tiles[i].o_dist_south, tiles[i-1].i_dist_north)
            wiring.connect(m, tiles[i].i_dist_south, tiles[i-1].o_dist_north)

        return m


if __name__ == "__main__":
    from amaranth_boards import rfsoc4x2
    class Top(Elaboratable):
        def elaborate(self, platform):
            m = Module()
            m.submodules.rfdc = rfdc = RFDCTilesUSP()
            for i in range(16):
                m.d.comb += rfdc.dac_samples[0][0][i].eq(i << 2)
                m.d.comb += rfdc.dac_samples[2][0][i].eq(i << 2)

            return m
    dut = Top()
    rfsoc4x2.RFSoC4x2Platform().build(dut, do_build=False).execute_remote_ssh(connect_to={"hostname": "10.60.0.194"}, root="/tmp")
