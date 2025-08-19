from amaranth import *
from amaranth.sim import Simulator
from amaranth.back import rtlil, verilog
from amaranth.lib.memory import Memory, WritePort, ReadPort
from amaranth.lib.wiring import Component, In, Out
from amaranth.lib import stream, wiring, data, enum, fifo, memory
from .trigger import trigger_event, CYCLE_BITS
from .uram import UltraRAM


class ImageCuber(wiring.Component):
    def __init__(self, fifo_depth = 2048, wavelength_cutoff_precision = 8):
        self.fifo_depth = fifo_depth
        self.wavelength_cutoff_precision = wavelength_cutoff_precision

        self.mem1 = UltraRAM(input_pipeline=False, output_pipeline=False)
        self.mem2 = UltraRAM(input_pipeline=False, output_pipeline=False)

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

        m.d.comb += [
            mem1.a.en.eq(1),
            mem1.a.we.eq(0b111111111),
            mem1.b.en.eq(1),
            mem1.b.we.eq(0b111111111),
            mem2.a.en.eq(1),
            mem2.a.we.eq(0b111111111),
            mem2.b.en.eq(1),
            mem2.b.we.eq(0b111111111),
        ]

        i = Signal(12)
        m.d.comb += self.current_cycle_number.eq(i+1)

        m.submodules.pixel_LUT = pixel_LUT = UltraRAM(input_pipeline=False, output_pipeline=False)
        m.submodules.wavelength_LUT = wavelength_LUT = UltraRAM(input_pipeline=False, output_pipeline=False)

        m.d.comb += [
            pixel_LUT.a.addr.eq(self.pixel_LUT_write.addr),
            pixel_LUT.a.dwrite.eq(self.pixel_LUT_write.data),
            pixel_LUT.a.write.eq(self.pixel_LUT_write.en),
            wavelength_LUT.a.addr.eq(self.wavelength_LUT_write.addr),
            wavelength_LUT.a.dwrite.eq(self.wavelength_LUT_write.data),
            wavelength_LUT.a.write.eq(self.wavelength_LUT_write.en),
            
            pixel_LUT.a.en.eq(1),
            pixel_LUT.a.we.eq(0b111111111),
            pixel_LUT.b.en.eq(1),
            pixel_LUT.b.we.eq(0b111111111),
            wavelength_LUT.a.en.eq(1),
            wavelength_LUT.a.we.eq(0b111111111),
            wavelength_LUT.b.en.eq(1),
            wavelength_LUT.b.we.eq(0b111111111),
        ]

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

        new_photon = Signal()
        LUTS_read = Signal()
        uploading = Signal()
        reading = Signal()

        def state_machine(a, b, machine_number):
            with m.FSM(init="Configuring"):
                with m.State("Configuring"):
                    m.d.sync += buffered_stream.ready.eq(0)
                    m.d.sync += a.write.eq(0)
                    m.d.sync += b.write.eq(0)

                    with m.If(self.generate_cubes):
                        with m.If(machine_number == 0):
                            m.next = "Clearing"
                        with m.Else():
                            m.next = "Stalling"

                with m.State("Clearing"):
                    m.d.sync += buffered_stream.ready.eq(0)
                    m.d.sync += a.write.eq(1)
                    m.d.sync += a.addr.eq(i)
                    m.d.sync += a.dwrite.eq(0)
                    m.d.sync += b.write.eq(1)
                    m.d.comb += b.addr.eq(2048-i)
                    m.d.sync += b.dwrite.eq(0)
                    m.d.sync += i.eq(i+1)

                    with m.If(i == 1024):
                        m.d.sync += a.write.eq(0)
                        m.d.sync += b.write.eq(0)
                        m.next = "Counting"
                    
                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"
                    
                with m.State("Counting"):
                    m.d.sync += buffered_stream.ready.eq(1)
                    m.d.sync += a.write.eq(0)
                    m.d.sync += b.write.eq(0)
                    m.d.sync += i.eq(i+1)
                    m.d.sync += new_photon.eq(0)

                    with m.If(buffered_stream.valid & buffered_stream.ready):
                        inc_bin = buffered_payload.bin
                        inc_phase = buffered_payload.phase

                        pixel = Signal(12)
                        pixel_to_upload = Signal(12)
                        wavelength_cutoffs = Signal(5*self.wavelength_cutoff_precision)
                        wavelength_bin = Signal(2)
                        not_within_bin = Signal()
                        muxer = Signal()
                        divided_phase = Signal(16)

                        m.d.sync += pixel_LUT.b.addr.eq(inc_bin)
                        m.d.sync += wavelength_LUT.b.addr.eq(inc_bin)
                        
                        m.d.sync += divided_phase.eq(inc_phase>>(16-self.wavelength_cutoff_precision))

                        m.d.sync += buffered_stream.ready.eq(0)
                        m.d.sync += new_photon.eq(1)
                    
                    with m.If(new_photon):
                        m.d.sync += LUTS_read.eq(1)
                        m.d.sync += new_photon.eq(0)
                        m.d.sync += buffered_stream.ready.eq(0)

                    with m.If(LUTS_read):
                        m.d.comb += pixel.eq(pixel_LUT.b.dread)
                        m.d.sync += muxer.eq(pixel[11])
                        m.d.comb += wavelength_cutoffs.eq(wavelength_LUT.b.dread)

                        m.d.sync += buffered_stream.ready.eq(0)

                        def wavelength_cutoff(n):
                            return wavelength_cutoffs[n*self.wavelength_cutoff_precision:(n+1)*self.wavelength_cutoff_precision]

                        with m.If((divided_phase >= wavelength_cutoff(0)) & (divided_phase < wavelength_cutoff(1))):
                            m.d.sync += wavelength_bin.eq(0)
                            m.d.sync += not_within_bin.eq(0)
                        with m.Elif((divided_phase >= wavelength_cutoff(1)) & (divided_phase < wavelength_cutoff(2))):
                            m.d.sync += wavelength_bin.eq(1)
                            m.d.sync += not_within_bin.eq(0)
                        with m.Elif((divided_phase >= wavelength_cutoff(2)) & (divided_phase < wavelength_cutoff(3))):
                            m.d.sync += wavelength_bin.eq(2)
                            m.d.sync += not_within_bin.eq(0)
                        with m.Elif((divided_phase >= wavelength_cutoff(3)) & (divided_phase < wavelength_cutoff(4))):
                            m.d.sync += wavelength_bin.eq(3)
                            m.d.sync += not_within_bin.eq(0)
                        with m.Else():
                            m.d.sync += not_within_bin.eq(1)

                        """
                        ADDRESS SCHEME: pixel = 4 x-bits + 8 y-bits (LSB is y, MSB is x)
                                        Use the 11 least significant bits as the memory address
                                        Take the most significant bit (MSB of x) and use it as a MUX
                                        If 0, then data = 32 lest significant of the 64 data bits at the address
                                        If 1, then data = 32 most significant of the 64 data bits at the address
                        """

                        m.d.sync += a.addr.eq(pixel[0:11])
                        m.d.comb += b.addr.eq(pixel[0:11])
                        m.d.sync += reading.eq(1)
                        m.d.sync += pixel_to_upload.eq(pixel)
                        m.d.sync += LUTS_read.eq(0)

                    with m.If((reading) & (~uploading)):
                        m.d.sync += a.addr.eq(pixel_to_upload[0:11])
                        m.d.comb += b.addr.eq(pixel_to_upload[0:11])

                        byte_array = Array([Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8)])
                        for j in range(8):
                            m.d.comb += byte_array[j].eq(b.dread[8*j:8*(j+1)])

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

                        m.d.sync += a.dwrite.eq(new_data)

                        m.d.sync += uploading.eq(1)
                        m.d.sync += buffered_stream.ready.eq(0)
                    

                    with m.If(uploading):
                        m.d.sync += a.addr.eq(pixel_to_upload[0:11])
                        m.d.comb += b.addr.eq(pixel_to_upload[0:11])
                        m.d.sync += buffered_stream.ready.eq(0)

                        m.d.sync += a.write.eq(1)

                        with m.If(a.write == 1):
                            m.d.sync += a.write.eq(0)
                            m.d.sync += uploading.eq(0)
                            m.d.sync += reading.eq(0)
                            m.d.sync += buffered_stream.ready.eq(1)


                    with m.If(i >= self.cycles_per_frame-1):
                        m.d.sync += i.eq(0)
                        m.d.sync += a.write.eq(0)
                        m.next = "Stalling"

                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"

                with m.State("Stalling"):
                    m.d.sync += i.eq(i+1)

                    m.d.comb += b.addr.eq(self.mem_read_addr)
                    m.d.comb += self.mem_read_data.eq(b.dread)
                    m.d.comb += self.mem_read_number.eq(machine_number)

                    with m.If(i == self.cycles_per_frame - 1):
                        m.d.sync += i.eq(0)
                        m.next = "Clearing"
                
                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"



        #State machine memory 1
        state_machine(mem1.a, mem1.b, 0)
        
        #State machine memory 2
        state_machine(mem2.a, mem2.b, 1)
        
        
        return m
    
    