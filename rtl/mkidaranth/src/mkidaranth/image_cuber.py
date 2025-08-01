from amaranth import *
from amaranth.sim import Simulator
from amaranth.back import rtlil, verilog
from amaranth.lib.memory import Memory, WritePort, ReadPort
from amaranth.lib.wiring import Component, In, Out
from amaranth.lib import stream, wiring, data, enum, fifo, memory
from .trigger import trigger_event, CYCLE_BITS


class ImageCuber(wiring.Component):
    def __init__(self, fifo_depth = 2048, wavelength_cutoff_precision = 8):
        self.fifo_depth = fifo_depth
        self.wavelength_cutoff_precision = wavelength_cutoff_precision

        self.mem1 = Memory(shape=unsigned(64), depth=2048, init=[])
        self.mem2 = Memory(shape=unsigned(64), depth=2048, init=[])

        self.event_payload_bits = 16 + 11 + 2 + CYCLE_BITS
        super().__init__(
            {
                "i_stream": In(stream.Signature(trigger_event)),
                "cycles_per_frame": In(16),
                "generate_cubes": In(1),
                "pixel_LUT_write": In(WritePort.Signature(addr_width=11, shape=unsigned(12))),
                "wavelength_LUT_write": In(WritePort.Signature(addr_width=11, shape=unsigned(5*wavelength_cutoff_precision))),
                "mem_read_addr": In(16),
                "mem_read_data": Out(64),
                "mem_read_number": Out(1),
                "lost_photon_flag": Out(1),
                "count_overflow_flag": Out(1),
                "current_cycle_number": Out(16),         #Will always be <= cycles_per_frame
            }
        )

    def elaborate(self, platform):
        m = Module()

        m.submodules.fifo_inst = fifo_inst = fifo.SyncFIFOBuffered(width = self.event_payload_bits, depth = self.fifo_depth)

        buffered_stream = fifo_inst.r_stream

        buffered_payload = Signal(trigger_event)
        m.d.comb += buffered_payload.eq(buffered_stream.payload)

        wiring.connect(m, wiring.flipped(self.i_stream), fifo_inst.w_stream)

        m.submodules.dmem1 = mem1 = self.mem1
        m.submodules.dmem2 = mem2 = self.mem2

        read_port1 = mem1.read_port(domain="comb")
        write_port11 = mem1.write_port(domain="sync")
        write_port12 = mem1.write_port(domain="sync")

        read_port2 = mem2.read_port(domain="comb")
        write_port21 = mem2.write_port(domain="sync")
        write_port22 = mem2.write_port(domain="sync")

        i = Signal(12)
        m.d.comb += self.current_cycle_number.eq(i+1)

        uploading = Signal()

        """
        For testing purposes, can use the following:

        pixel_LUT_init = []
        for xx in range(14):
            for yy in range(146):
                pixel_LUT_init.append((xx<<8) | yy)
        """

        m.submodules.pixel_LUT = pixel_LUT = Memory(shape = unsigned(12), depth = 2048, init = [])
        pixel_LUT_write = pixel_LUT.write_port(domain="sync")
        wiring.connect(m, self.pixel_LUT_write, pixel_LUT_write)
        pixel_LUT_read = pixel_LUT.read_port(domain="comb")

        """
        For testing purposes, can use the following:

        wavelength_LUT_init = []
        for _ in range(2048):
            wavelength_LUT_init.append(0b0111111100011111000001110000001100000001)
        """

        m.submodules.wavelength_LUT = wavelength_LUT = Memory(shape = unsigned(5*self.wavelength_cutoff_precision), depth = 2048, init = [])
        wavelength_LUT_write = wavelength_LUT.write_port(domain="sync")
        wiring.connect(m, self.wavelength_LUT_write, wavelength_LUT_write)
        wavelength_LUT_read = wavelength_LUT.read_port(domain="comb")

        #Error detection
        m.d.sync += self.lost_photon_flag.eq(0)
        m.d.sync += self.count_overflow_flag.eq(0)

        temp_payload = Signal(self.event_payload_bits)
        prev_payload = Signal(self.event_payload_bits)

        m.d.sync += prev_payload.eq(self.i_stream.payload)

        with m.If(fifo_inst.w_en & fifo_inst.w_rdy):
            m.d.sync += temp_payload.eq(fifo_inst.w_data)

        with m.If(fifo_inst.level >= fifo_inst.depth - 2):
            with m.If(Signal.cast(self.i_stream.payload) != prev_payload):
                with m.If(prev_payload != temp_payload):
                    m.d.sync += self.lost_photon_flag.eq(1)   #Throws error pulse when photon event isn't read due to FIFO overflow


        def state_machine(write_port1, write_port2, read_port, machine_number):
            with m.FSM(init="Configuring"):
                with m.State("Configuring"):
                    m.d.sync += buffered_stream.ready.eq(0)
                    m.d.sync += write_port1.en.eq(0)
                    m.d.sync += write_port2.en.eq(0)
                    m.d.comb += read_port.addr.eq(0)

                    with m.If(self.generate_cubes):
                        with m.If(machine_number == 0):
                            m.next = "Clearing"
                        with m.Else():
                            m.next = "Stalling"

                with m.State("Clearing"):
                    m.d.sync += buffered_stream.ready.eq(0)
                    m.d.sync += write_port1.en.eq(1)
                    m.d.sync += write_port1.addr.eq(i)
                    m.d.sync += write_port1.data.eq(0)
                    m.d.sync += write_port2.en.eq(1)
                    m.d.sync += write_port2.addr.eq(2047-i)
                    m.d.sync += write_port2.data.eq(0)
                    m.d.comb += read_port.addr.eq(0)
                    m.d.sync += i.eq(i+1)

                    with m.If(i == 1024):
                        m.d.sync += write_port1.en.eq(0)
                        m.d.sync += write_port2.en.eq(0)
                        m.next = "Counting"
                    
                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"
                    
                with m.State("Counting"):
                    m.d.sync += buffered_stream.ready.eq(1)
                    m.d.sync += write_port1.en.eq(0)
                    m.d.sync += write_port2.en.eq(0)
                    m.d.sync += i.eq(i+1)

                    with m.If(buffered_stream.valid & buffered_stream.ready):
                        inc_bin = buffered_payload.bin
                        inc_phase = buffered_payload.phase

                        pixel = Signal(12)
                        pixel_to_upload = Signal(12)
                        wavelength_cutoffs = Signal(5*self.wavelength_cutoff_precision)
                        wavelength_bin = Signal(2)
                        not_within_bin = Signal()

                        m.d.comb += pixel_LUT_read.addr.eq(inc_bin)
                        m.d.comb += pixel.eq(pixel_LUT_read.data)
                    
                        m.d.comb += wavelength_LUT_read.addr.eq(inc_bin)
                        m.d.comb += wavelength_cutoffs.eq(wavelength_LUT_read.data)
                        
                        divided_phase = inc_phase>>(16-self.wavelength_cutoff_precision)

                        def wavelength_cutoff(n):
                            return wavelength_cutoffs[n*self.wavelength_cutoff_precision:(n+1)*self.wavelength_cutoff_precision]

                        with m.If((divided_phase >= wavelength_cutoff(0)) & (divided_phase < wavelength_cutoff(1))):
                            m.d.comb += wavelength_bin.eq(0)
                        with m.Elif((divided_phase >= wavelength_cutoff(1)) & (divided_phase < wavelength_cutoff(2))):
                            m.d.comb += wavelength_bin.eq(1)
                        with m.Elif((divided_phase >= wavelength_cutoff(2)) & (divided_phase < wavelength_cutoff(3))):
                            m.d.comb += wavelength_bin.eq(2)
                        with m.Elif((divided_phase >= wavelength_cutoff(3)) & (divided_phase < wavelength_cutoff(4))):
                            m.d.comb += wavelength_bin.eq(3)
                        with m.Else():
                            m.d.comb += not_within_bin.eq(1)

                        """
                        ADDRESS SCHEME: pixel = 4 x-bits + 8 y-bits (LSB is y, MSB is x)
                                        Use the 11 least significant bits as the memory address
                                        Take the most significant bit (MSB of x) and use it as a MUX
                                        If 0, then data = 32 lest significant of the 64 data bits at the address
                                        If 1, then data = 32 most significant of the 64 data bits at the address
                        """

                        m.d.sync += write_port1.addr.eq(pixel[0:11])
                        m.d.comb += read_port.addr.eq(pixel[0:11])
                        muxer = Signal()
                        m.d.comb += muxer.eq(pixel[11])

                        with m.If(~uploading):
                            byte_array = Array([Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8)])
                            for j in range(8):
                                m.d.comb += byte_array[j].eq(read_port.data[8*j:8*(j+1)])

                            index = wavelength_bin | (muxer<<2)                      

                            byte_array_new = Array([Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8)])

                            m.d.sync += self.count_overflow_flag.eq(0)
                            for j in range(8):
                                with m.If((j == index) & (byte_array[j] != 0b11111111) & (not_within_bin == 0)):
                                    m.d.comb += byte_array_new[j].eq((byte_array[j] + 1)[:8])
                                with m.Elif((j == index) & (byte_array[j] == 0b11111111) & (not_within_bin == 0)):
                                    m.d.comb += byte_array_new[j].eq(byte_array[j])
                                    m.d.sync += self.count_overflow_flag.eq(1)
                                with m.Else():
                                    m.d.comb += byte_array_new[j].eq(byte_array[j])

                            new_data = Cat(byte_array_new[j] for j in range(8))

                            m.d.sync += write_port1.data.eq(new_data)

                            m.d.sync += uploading.eq(1)
                            m.d.sync += pixel_to_upload.eq(pixel)
                            m.d.sync += buffered_stream.ready.eq(0)
                    

                    with m.If(uploading):
                        m.d.sync += write_port1.addr.eq(pixel_to_upload[0:11])
                        m.d.comb += read_port.addr.eq(pixel_to_upload[0:11])
                        m.d.sync += buffered_stream.ready.eq(0)

                        m.d.sync += write_port1.en.eq(1)

                        with m.If(write_port1.en == 1):
                            m.d.sync += write_port1.en.eq(0)
                            m.d.sync += uploading.eq(0)
                            m.d.sync += buffered_stream.ready.eq(1)


                    with m.If(i >= self.cycles_per_frame-1):
                        m.d.sync += i.eq(0)
                        m.d.sync += write_port1.en.eq(0)
                        m.next = "Stalling"

                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"

                with m.State("Stalling"):
                    m.d.sync += i.eq(i+1)

                    m.d.comb += read_port.addr.eq(self.mem_read_addr)
                    m.d.comb += self.mem_read_data.eq(read_port.data)
                    m.d.comb += self.mem_read_number.eq(machine_number)

                    with m.If(i == self.cycles_per_frame - 1):
                        m.d.sync += i.eq(0)
                        m.next = "Clearing"
                
                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"



        #State machine memory 1
        state_machine(write_port11, write_port12, read_port1, 0)
        
        #State machine memory 2
        state_machine(write_port21, write_port22, read_port2, 1)
        
        
        return m
    
    