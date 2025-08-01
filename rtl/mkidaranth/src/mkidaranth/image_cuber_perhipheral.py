from amaranth import *

from amaranth.lib import wiring, memory, stream, data, fifo
from amaranth.lib.wiring import In, Out, Component
from amaranth.utils import exact_log2
from amaranth_soc import csr

from .trigger import trigger_event, CYCLE_BITS
from .image_cuber import ImageCuber
from . import axi

class AddressGenerator(wiring.Component):
    def __init__(self, len_bits=8, size_bits=3, type_bits=2, addr_bits=15, id_bits=2):
        self.len_bits = len_bits
        self.size_bits = size_bits
        self.type_bits = type_bits
        self.addr_bits = addr_bits
        self.id_bits = id_bits

        super().__init__(
            {
                "len": In(len_bits),
                "size": In(size_bits),
                "type": In(type_bits),
                "start_byte_addr": In(addr_bits),
                "start_generate": In(1),
                "byte_addr": Out(addr_bits),
                "last": Out(1),
                "lower_byte_lane": Out(4),
                "upper_byte_lane": Out(4),
            }
        )
    
    def elaborate(self, platform):
        m = Module()

        start_addr = self.start_byte_addr
        num_bytes = 1 << self.size
        burst_length = self.len + 1
        aligned_addr = (start_addr // num_bytes) * num_bytes
        data_bus_bytes = 8

        wrap_bound = (start_addr // (num_bytes * burst_length)) * (num_bytes * burst_length)

        init_lower_byte_lane = start_addr - (start_addr // data_bus_bytes) * data_bus_bytes
        init_upper_byte_lane = aligned_addr + (num_bytes - 1) - (start_addr // data_bus_bytes) * data_bus_bytes

        generating = Signal(1)
        n = Signal(8)

        m.d.sync += self.lower_byte_lane.eq(init_lower_byte_lane)
        m.d.sync += self.upper_byte_lane.eq(init_upper_byte_lane)
        m.d.sync += self.last.eq(0)

        with m.If(self.start_generate):
            m.d.sync += self.byte_addr.eq(self.start_byte_addr)
            with m.If(burst_length == 1):
                m.d.sync += self.last.eq(1)
            with m.Else():
                m.d.sync += generating.eq(1)
                m.d.sync += n.eq(n+1)


        with m.If(generating):
            with m.If(self.type == 0):   #FIXED
                m.d.sync += n.eq(n+1)
                with m.If(n == burst_length - 1):
                    m.d.sync += n.eq(0)
                    m.d.sync += self.last.eq(1)
                    m.d.sync += generating.eq(0)

            with m.Elif(self.type == 1):   #INCR
                next_addr = aligned_addr + (n*num_bytes)
                m.d.sync += self.byte_addr.eq(next_addr)
                m.d.sync += self.lower_byte_lane.eq(next_addr - ((next_addr // data_bus_bytes) * data_bus_bytes))
                m.d.sync += self.upper_byte_lane.eq(next_addr - ((next_addr // data_bus_bytes) * data_bus_bytes) + num_bytes - 1)
                m.d.sync += n.eq(n+1)
                with m.If(n == burst_length - 1):
                    m.d.sync += n.eq(0)
                    m.d.sync += self.last.eq(1)
                    m.d.sync += generating.eq(0)

            with m.Elif(self.type == 2):  #WRAP
                m.d.sync += n.eq(n+1)
                wrapped = Signal(1)
                
                with m.If(~wrapped):
                    next_addr = aligned_addr + (n*num_bytes)
                    m.d.sync += self.byte_addr.eq(next_addr)
                    with m.If(next_addr >= (wrap_bound + (num_bytes * burst_length))):
                        m.d.sync += self.byte_addr.eq(wrap_bound)
                        m.d.sync += wrapped.eq(1)
                with m.Else():
                    next_addr = self.byte_addr + num_bytes
                    m.d.sync += self.byte_addr.eq(next_addr)
                
                with m.If(n == burst_length - 1):
                    m.d.sync += n.eq(0)
                    m.d.sync += self.last.eq(1)
                    m.d.sync += generating.eq(0)

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
    

    def __init__(self, *, csr_addr_width, csr_data_width):
        self.cuber = ImageCuber()
        regs = csr.Builder(addr_width=csr_addr_width, data_width=csr_data_width)
        self._cpf = regs.add("CPF", self.CPF())
        self._runcuber = regs.add("RunCuber", self.RunCuber())
        self._errorcounts = regs.add("ErrorCounts", self.ErrorCounts())
        self._pixelLUTconfig = regs.add("pixelLUTconfig", self.pixelLUTconfig())
        self._wavelengthLUTconfig = regs.add("wavelengthLUTconfig", self.wavelengthLUTconfig())
        self._bridge = csr.Bridge(regs.as_memory_map())

        super().__init__(
            {
                "bus": In(csr.Signature(addr_width=csr_addr_width, data_width=csr_data_width)),
                "membus": In(axi.Signature(axi.Axi4Properties(QOS_Present=False, PROT_Present=False, CACHE_Present=False, Exclusive_Accesses=False, READ_WRITE_MODE=axi.ReadWriteMode.READ_ONLY, ADDR_WIDTH=16, REGION_Present=False, DATA_WIDTH=64, WSTRB_Present=False, WLAST_Present=False, ID_W_WIDTH=0, ID_R_WIDTH=2))),
                "trigger_stream": In(stream.Signature(trigger_event)),
                "int": Out(1),
                "axi_status": Out(1),    #HIGH means that an axi burst is either queued (waiting for memory access) or currently in progress
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


        #AXI code
        address_gen_queued = Signal(1)
        m.d.comb += self.axi_status.eq(address_gen_queued)

        with m.If(generate_cubes & ~address_gen_queued):
            m.d.sync += self.membus.ar.ready.eq(1)

        """
        AXI address scheme:

        First 15 LSBs (bits 0-14) of the AXI address is the byte address
        
        The memory address is the byte address divided by 8 rounded down (since the memory data is 8 bytes)
        
        Bit 15 of the axi address is the mem_number, which indicated which memory module the CPU is trying to read from
        (mem_number = 0 --> mem1  |  mem_number = 1 --> mem2)

        Ready doesn't go HIGH until mem_number matches with the available memory module
        """

        m.submodules.address_generator = address_generator = AddressGenerator()
        mem_address = address_generator.byte_addr >> 3
        mem_number = self.membus.ar.payload.addr[15]

        m.d.comb += cuber.mem_read_addr.eq(mem_address)
        m.d.comb += self.membus.r.payload.data.eq(cuber.mem_read_data)
        m.d.comb += self.membus.r.payload.id.eq(self.membus.ar.payload.id)
        
        m.d.comb += self.membus.r.payload.last.eq(address_generator.last)
        m.d.comb += address_generator.start_generate.eq(self.membus.r.valid & self.membus.r.ready)

        waiting_to_generate = Signal(1)

        with m.If((self.membus.ar.valid == 1) & (self.membus.ar.ready == 1)):
            m.d.sync += address_generator.len.eq(self.membus.ar.payload.len)
            m.d.sync += address_generator.size.eq(self.membus.ar.payload.size)
            m.d.sync += address_generator.type.eq(self.membus.ar.payload.burst)
            m.d.sync += address_generator.start_byte_addr.eq(self.membus.ar.payload.addr[0:15])
            m.d.sync += address_gen_queued.eq(1)
            m.d.sync += self.membus.ar.ready.eq(0)

            with m.If((mem_number == cuber.mem_read_number) & (self.membus.ar.payload.len < self.cuber.cycles_per_frame-self.cuber.current_cycle_number)):
                m.d.sync += self.membus.r.valid.eq(1)
            with m.Else():
                m.d.sync += waiting_to_generate.eq(1)
        
        with m.If(waiting_to_generate):
            with m.If((mem_number == cuber.mem_read_number) & (self.membus.ar.payload.len < self.cuber.cycles_per_frame-self.cuber.current_cycle_number)):
                m.d.sync += self.membus.r.valid.eq(1)
                m.d.sync += waiting_to_generate.eq(0)

        with m.If((self.membus.r.valid == 1) & (self.membus.r.ready == 1)):
            m.d.sync += self.membus.r.valid.eq(0)
        
        with m.If(self.membus.r.payload.last):
            m.d.sync += address_gen_queued.eq(0)
            m.d.sync += self.membus.ar.ready.eq(1)



        return m

