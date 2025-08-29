from amaranth import *

from amaranth.lib import wiring, memory, stream, data, fifo
from amaranth.lib.wiring import In, Out, Component
from amaranth.utils import exact_log2
from amaranth_soc import csr

from .trigger import trigger_event, CYCLE_BITS, StreamPipelineStage
from .image_cuber import ImageCuber
from . import axi
from .axi import BurstEncoding

cuber_axi_signature = axi.Signature(
    axi.Axi4Properties(
            QOS_Present=False, PROT_Present=False, CACHE_Present=False, Exclusive_Accesses=False,
            READ_WRITE_MODE=axi.ReadWriteMode.READ_ONLY, ADDR_WIDTH=16, REGION_Present=False,
            DATA_WIDTH=64, WSTRB_Present=False, WLAST_Present=False, ID_W_WIDTH=16, ID_R_WIDTH=16
        )
    )

address_generator_props = axi.Axi4Properties(
    ADDR_WIDTH=16,
    DATA_WIDTH=64,
    Exclusive_Accesses=False,
    REGION_Present=False,
    CACHE_Present=False,
    PROT_Present=False,
    QOS_Present=False,
    ID_W_WIDTH=16,
    ID_R_WIDTH=16
)


class AddressGenerator(wiring.Component):
    def __init__(self):
        super().__init__(
            {
                "ar": In(stream.Signature(axi.ReadRequestChannel(cuber_axi_signature.props), payload_init=axi.ReadRequestChannel(cuber_axi_signature.props).INIT)),
                "addresses": Out(stream.Signature(data.StructLayout({"mem_num": 1, "byte_addr": address_generator_props.ADDR_WIDTH-1, "last": 1, "id": address_generator_props.ID_R_WIDTH}))),
            }
        )
    
    def elaborate(self, platform):
        m = Module()

        ar_saved = Signal(axi.ReadRequestChannel(cuber_axi_signature.props))
        log2_burst_length = Signal(4)
        wrap_address = Signal(cuber_axi_signature.props.ADDR_WIDTH)
        aligned_address = Signal(cuber_axi_signature.props.ADDR_WIDTH)
        increment_amount = Signal(cuber_axi_signature.props.ADDR_WIDTH)

        running = Signal()
        generating = Signal()
        compute_addresses = Signal()
        n = Signal(8)

        m.d.sync += self.ar.ready.eq(1)
        with m.If(running):
            m.d.sync += self.ar.ready.eq(0)

        with m.If(self.ar.valid & self.ar.ready):
            m.d.sync += self.ar.ready.eq(0)
            m.d.sync += ar_saved.eq(self.ar.payload)
            m.d.sync += compute_addresses.eq(1)
            m.d.sync += running.eq(1)

        with m.If(compute_addresses):
            with m.FSM():
                with m.State("Start"):
                    # Setting lowest n bits to 0 where n = size
                    m.d.sync += [
                        aligned_address.eq((ar_saved.addr >> ar_saved.size) << ar_saved.size),
                        self.addresses.payload.byte_addr.eq(ar_saved.addr),
                        increment_amount.eq(1 << self.ar.payload.size)
                    ]
                    burst_length = ar_saved.len + 1
                    with m.Switch(burst_length):
                        with m.Case(2):
                            m.d.sync += log2_burst_length.eq(1)
                        with m.Case(4):
                            m.d.sync += log2_burst_length.eq(2)
                        with m.Case(8):
                            m.d.sync += log2_burst_length.eq(3)
                        with m.Case(16):
                            m.d.sync += log2_burst_length.eq(4)
                    m.next = "Compute Wrap"
                with m.State("Compute Wrap"):
                    m.d.sync += wrap_address.eq((ar_saved.addr >> (ar_saved.size + log2_burst_length)) << (ar_saved.size + log2_burst_length))
                    with m.If(ar_saved.burst == BurstEncoding.WRAP):
                        m.d.sync += self.addresses.payload.byte_addr.eq(aligned_address)
                    with m.If(ar_saved.len == 0):
                        m.d.sync += self.addresses.payload.last.eq(1)

                    m.d.sync += compute_addresses.eq(0)
                    m.d.sync += self.addresses.valid.eq(1)

                    m.d.sync += self.addresses.payload.mem_num.eq(ar_saved.addr[15])
                    m.d.sync += self.addresses.payload.id.eq(ar_saved.id)

                    m.next = "Start"

        m.d.comb += generating.eq(self.addresses.valid & self.addresses.ready)

        with m.If(generating):
            m.d.sync += n.eq(n + 1)
            with m.If(self.ar.payload.burst == BurstEncoding.FIXED):
                pass
            with m.Elif(self.ar.payload.burst == BurstEncoding.INCR):
                m.d.sync += self.addresses.payload.byte_addr.eq(self.addresses.payload.byte_addr + increment_amount)
            with m.Elif(self.ar.payload.burst == BurstEncoding.WRAP):
                with m.If(self.addresses.payload.byte_addr + increment_amount == wrap_address):
                    m.d.sync += self.addresses.payload.byte_addr.eq(aligned_address)
                with m.Else():
                    m.d.sync += self.addresses.payload.byte_addr.eq(self.addresses.payload.byte_addr + increment_amount)
            with m.If(n == ar_saved.len - 1):
                m.d.sync += self.addresses.payload.last.eq(1)

        with m.If((self.addresses.payload.last == 1) & self.addresses.valid & self.addresses.ready):
            m.d.sync += n.eq(0)
            m.d.sync += running.eq(0)
            m.d.sync += self.addresses.valid.eq(0)
            m.d.sync += self.addresses.payload.last.eq(0)

        return m


class CuberPeri(wiring.Component):
    class CPF(csr.Register, access = "rw"):
        cpf: csr.Field(csr.action.RW, 16)
    class RunCuber(csr.Register, access = "rw"):
        generate_cubes: csr.Field(csr.action.RW, 1)
    class ErrorCounts(csr.Register, access = "rw"):
        lost_photon: csr.Field(csr.action.R, 16)
        count_overflow: csr.Field(csr.action.R, 16)
    class pixelLUTconfig(csr.Register, access = "rw"):
        pixelLUTconfig: csr.Field(
            csr.action.W,
            data.StructLayout({"bin": 11, "xpos": 4, "ypos": 8}),
        )
    class wavelengthLUTconfig(csr.Register, access = "rw"):
        wavelengthLUTconfig: csr.Field(
            csr.action.W,
            data.StructLayout({"bin": 11, "edge0": 16, "edge1": 16, "edge2": 16, "edge3": 16, "edge4": 16}),
        )
    
    class debugRegister(csr.Register, access = "r"):
        trigger_stream_valid: csr.Field(csr.action.R, 1)
        trigger_stream_ready: csr.Field(csr.action.R, 1)
        membus_ar_valid: csr.Field(csr.action.R, 1)
        membus_ar_ready: csr.Field(csr.action.R, 1)
        membus_r_valid: csr.Field(csr.action.R, 1)
        membus_r_ready: csr.Field(csr.action.R, 1)
        current_cycle: csr.Field(csr.action.R, 16)
    

    def __init__(self, *, csr_addr_width, csr_data_width, debug_reg=True):
        self.debug_reg = debug_reg
        self.cuber = ImageCuber()
        regs = csr.Builder(addr_width=csr_addr_width, data_width=csr_data_width)
        self._cpf = regs.add("CPF", self.CPF())
        self._runcuber = regs.add("RunCuber", self.RunCuber())
        self._errorcounts = regs.add("ErrorCounts", self.ErrorCounts())
        self._pixelLUTconfig = regs.add("pixelLUTconfig", self.pixelLUTconfig())
        self._wavelengthLUTconfig = regs.add("wavelengthLUTconfig", self.wavelengthLUTconfig())
        if self.debug_reg:
            self._debug = regs.add("debugRegister", self.debugRegister())
        self._bridge = csr.Bridge(regs.as_memory_map())

        super().__init__(
            {
                "bus": In(csr.Signature(addr_width=csr_addr_width, data_width=csr_data_width)),
                "membus": In(cuber_axi_signature),
                "trigger_stream": In(stream.Signature(trigger_event)),
                "int": Out(1),
            }
        )

        self.bus.memory_map = self._bridge.bus.memory_map

    def elaborate(self, platform):
        m = Module()

        #CSR code
        m.submodules.bridge = self._bridge
        wiring.connect(m, wiring.flipped(self.bus), self._bridge.bus)

        cpf = Signal(16, reset_less=True)
        m.d.comb += cpf.eq(self._cpf.f.cpf.data)

        generate_cubes = Signal(1, reset_less=True)
        m.d.comb += generate_cubes.eq(self._runcuber.f.generate_cubes.data)

        lost_photon = Signal(16, reset_less=True)
        m.d.comb += self._errorcounts.f.lost_photon.r_data.eq(lost_photon)

        count_overflow = Signal(16, reset_less=True)
        m.d.comb += self._errorcounts.f.count_overflow.r_data.eq(count_overflow)

        m.submodules.cuber = cuber = self.cuber
        wiring.connect(m, wiring.flipped(self.trigger_stream), cuber.i_stream)

        m.d.comb += cuber.cycles_per_frame.eq(cpf)
        m.d.comb += cuber.generate_cubes.eq(generate_cubes)
        
        with m.If(cuber.lost_photon_flag == 1):
            m.d.sync += lost_photon.eq(lost_photon + 1)
        with m.If(cuber.count_overflow_flag == 1):
            m.d.sync += count_overflow.eq(count_overflow + 1)

        error_reg_start = self.bus.memory_map.find_resource(self._errorcounts).start

        with m.If((self.bus.addr == error_reg_start) & (self.bus.r_stb == 1)):
            m.d.sync += lost_photon.eq(0)
        with m.If((self.bus.addr == error_reg_start+1) & (self.bus.r_stb == 1)):
            m.d.sync += count_overflow.eq(0)

        m.d.comb += self.int.eq((lost_photon > 0) | (count_overflow > 0))
        
        m.d.sync += cuber.pixel_LUT_write.addr.eq(self._pixelLUTconfig.f.pixelLUTconfig.w_data.bin)
        m.d.sync += cuber.pixel_LUT_write.data.eq((self._pixelLUTconfig.f.pixelLUTconfig.w_data.xpos<<8) | self._pixelLUTconfig.f.pixelLUTconfig.w_data.ypos)
        m.d.sync += cuber.pixel_LUT_write.en.eq(self._pixelLUTconfig.f.pixelLUTconfig.w_stb)

        def getBinEdges(data):
            edges = Signal(5*cuber.wavelength_cutoff_precision)
            edges = edges | (data.edge0 >> (16-cuber.wavelength_cutoff_precision))
            edges = edges | ((data.edge1 >> (16-cuber.wavelength_cutoff_precision)) << 1*cuber.wavelength_cutoff_precision)
            edges = edges | ((data.edge2 >> (16-cuber.wavelength_cutoff_precision)) << 2*cuber.wavelength_cutoff_precision)
            edges = edges | ((data.edge3 >> (16-cuber.wavelength_cutoff_precision)) << 3*cuber.wavelength_cutoff_precision)
            edges = edges | ((data.edge4 >> (16-cuber.wavelength_cutoff_precision)) << 4*cuber.wavelength_cutoff_precision)

            return edges

        m.d.sync += cuber.wavelength_LUT_write.addr.eq(self._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data.bin)
        m.d.sync += cuber.wavelength_LUT_write.data.eq(getBinEdges(self._wavelengthLUTconfig.f.wavelengthLUTconfig.w_data))
        m.d.sync += cuber.wavelength_LUT_write.en.eq(self._wavelengthLUTconfig.f.wavelengthLUTconfig.w_stb)


        if self.debug_reg:
            m.d.sync += [
                self._debug.f.trigger_stream_valid.r_data.eq(self.trigger_stream.valid),
                self._debug.f.trigger_stream_ready.r_data.eq(self.trigger_stream.ready),
                self._debug.f.membus_ar_valid.r_data.eq(self.membus.ar.valid),
                self._debug.f.membus_ar_ready.r_data.eq(self.membus.ar.ready),
                self._debug.f.membus_r_valid.r_data.eq(self.membus.r.valid),
                self._debug.f.membus_r_ready.r_data.eq(self.membus.r.ready),
                self._debug.f.current_cycle.r_data.eq(cuber.current_cycle_number),
            ]

        #AXI code
        """
        AXI address scheme:

        First 15 LSBs (bits 0-14) of the AXI address is the byte address
        
        The memory address is the byte address divided by 8 rounded down (since the memory data is 8 bytes)
        
        Bit 15 of the axi address is the mem_number, which indicated which memory module the CPU is trying to read from
        (mem_number = 0 --> mem1  |  mem_number = 1 --> mem2)
        """

        m.submodules.address_generator = address_generator = AddressGenerator()
        m.submodules.address_pipeline = address_pipeline = StreamPipelineStage(address_generator.addresses.payload.shape())

        wiring.connect(m, wiring.flipped(self.membus.ar), address_generator.ar)

        wiring.connect(m, address_generator.addresses, address_pipeline.input)
        
        m.d.comb += [
            cuber.mem_read.payload.addr.eq(address_pipeline.output.payload.byte_addr >> 3),
            cuber.mem_read.payload.last.eq(address_pipeline.output.payload.last),
            cuber.mem_read.payload.mem_num.eq(address_pipeline.output.payload.mem_num),
            cuber.mem_read.payload.id.eq(address_pipeline.output.payload.id),
            cuber.mem_read.valid.eq(address_pipeline.output.valid),
            address_pipeline.output.ready.eq(cuber.mem_read.ready),
        ]



        m.d.comb += cuber.mem_read_output.ready.eq(0)

        with m.If(~self.membus.r.valid & cuber.mem_read_output.valid):
            m.d.comb += cuber.mem_read_output.ready.eq(1)
            m.d.sync += [
                self.membus.r.payload.data.eq(cuber.mem_read_output.payload.data),
                self.membus.r.payload.last.eq(cuber.mem_read_output.payload.last),
                self.membus.r.payload.id.eq(cuber.mem_read_output.payload.id),
                self.membus.r.valid.eq(1),
            ]
        
        with m.If(self.membus.r.valid & self.membus.r.ready):
            m.d.sync += self.membus.r.valid.eq(0)
            with m.If(cuber.mem_read_output.valid):
                m.d.comb += cuber.mem_read_output.ready.eq(1)
                m.d.sync += [
                    self.membus.r.payload.data.eq(cuber.mem_read_output.payload.data),
                    self.membus.r.payload.last.eq(cuber.mem_read_output.payload.last),
                    self.membus.r.payload.id.eq(cuber.mem_read_output.payload.id),
                    self.membus.r.valid.eq(1),
                ]


        return m

