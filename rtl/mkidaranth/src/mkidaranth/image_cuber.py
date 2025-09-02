from amaranth import *
from amaranth.sim import Simulator
from amaranth.back import rtlil, verilog
from amaranth.lib.memory import Memory, WritePort, ReadPort
from amaranth.lib.wiring import Component, In, Out
from amaranth.lib import stream, wiring, data, enum, fifo, memory
from .trigger import trigger_event, CYCLE_BITS
from .uram import UltraRAM
from .skid import SkidBuffer

ID_R_WIDTH = 16

main_user_data_shape = data.StructLayout({"last": 1, "id": ID_R_WIDTH})

class URAMPortFormatter(wiring.Component):
    def __init__(self, port, user_data_shape=unsigned(0)):
        self.user_data_shape = user_data_shape
        self.port = port
        
        super().__init__(
            {
                "write": In(stream.Signature(data.StructLayout({"addr": 12, "data": 72}))),
                "read": In(stream.Signature(data.StructLayout({"addr": 12, "user_data": user_data_shape}))),
                "read_output": Out(stream.Signature(data.StructLayout({"data": 72, "user_data": user_data_shape})))
            }
        )
    
    def elaborate(self, platform):
        m = Module()

        m.d.comb += [
            self.write.ready.eq(1),
            self.port.en.eq((self.read.valid & self.read.ready) | (self.write.valid & self.write.ready)),
            self.port.write.eq(self.write.valid & self.write.ready),
            self.port.dwrite.eq(self.write.payload.data),
            self.port.we.eq(0b111111111),
        ]

        with m.If(self.write.valid):
            m.d.comb += self.port.addr.eq(self.write.payload.addr)
        with m.Elif(self.read.valid):
            m.d.comb += self.port.addr.eq(self.read.payload.addr)
            m.d.comb += self.port.dread_user.eq(self.read.payload.user_data)
    

        m.submodules.skid_buffer = skid_buffer = SkidBuffer(shape=data.StructLayout({"data": 72, "user_data": self.user_data_shape}), depth=4)

        m.d.comb += [
            skid_buffer.i.payload.data.eq(self.port.dread),
            skid_buffer.i.payload.user_data.eq(self.port.dread_user_out),
            skid_buffer.i.valid.eq(self.port.dread_valid),
            self.read.ready.eq((skid_buffer.i.ready | (~skid_buffer.o.valid)) & (~self.write.valid)),
        ]

        wiring.connect(m, skid_buffer.o, wiring.flipped(self.read_output))

        """
        m.d.comb += [
            self.read_output.payload.data.eq(skid_buffer.o.payload.data),
            self.read_output.payload.user_data.eq(skid_buffer.o.payload.user_data),
            self.read_output.valid.eq(skid_buffer.o.valid),
            skid_buffer.o.ready.eq(self.read_output.ready)
        ]
        """
            

        return m

class ImageCuber(wiring.Component):
    def __init__(self, fifo_depth = 2048, wavelength_cutoff_precision = 8):
        self.fifo_depth = fifo_depth
        self.wavelength_cutoff_precision = wavelength_cutoff_precision

        self.mem1 = UltraRAM(input_pipeline=False, output_pipeline=True, user_shape=main_user_data_shape)
        self.mem2 = UltraRAM(input_pipeline=False, output_pipeline=True, user_shape=main_user_data_shape)

        self.event_payload_bits = 16 + 11 + 2 + CYCLE_BITS
        super().__init__(
            {
                "i_stream": In(stream.Signature(trigger_event)),
                "cycles_per_frame": In(16),
                "generate_cubes": In(1),
                "pixel_LUT_write": In(WritePort.Signature(addr_width=11, shape=unsigned(12))),
                "wavelength_LUT_write": In(WritePort.Signature(addr_width=11, shape=unsigned(5*wavelength_cutoff_precision))),
                "mem_read": In(stream.Signature(data.StructLayout({"addr": 12, "mem_num": 1, "last": 1, "id": ID_R_WIDTH}))),
                "mem_read_output": Out(stream.Signature(data.StructLayout({"data": 64, "mem_num": 1, "last": 1, "id": ID_R_WIDTH}))),
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

        m.submodules.mem1fa = mem1fa = URAMPortFormatter(mem1.a, user_data_shape=main_user_data_shape)
        m.submodules.mem1fb = mem1fb = URAMPortFormatter(mem1.b, user_data_shape=main_user_data_shape)
        m.submodules.mem2fa = mem2fa = URAMPortFormatter(mem2.a, user_data_shape=main_user_data_shape)
        m.submodules.mem2fb = mem2fb = URAMPortFormatter(mem2.b, user_data_shape=main_user_data_shape)

        i = Signal(12)
        m.d.comb += self.current_cycle_number.eq(i+1)

        m.submodules.pixel_LUT = pixel_LUT = UltraRAM(input_pipeline=False, output_pipeline=True)
        m.submodules.wavelength_LUT = wavelength_LUT = UltraRAM(input_pipeline=False, output_pipeline=True)

        m.d.comb += [
            pixel_LUT.a.addr.eq(self.pixel_LUT_write.addr),
            pixel_LUT.a.dwrite.eq(self.pixel_LUT_write.data),
            pixel_LUT.a.write.eq(self.pixel_LUT_write.en),
            wavelength_LUT.a.addr.eq(self.wavelength_LUT_write.addr),
            wavelength_LUT.a.dwrite.eq(self.wavelength_LUT_write.data),
            wavelength_LUT.a.write.eq(self.wavelength_LUT_write.en),
            
            pixel_LUT.a.en.eq(1),
            pixel_LUT.a.we.eq(0b111111111),
            pixel_LUT.b.we.eq(0b111111111),
            wavelength_LUT.a.en.eq(1),
            wavelength_LUT.a.we.eq(0b111111111),
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

        counting = Signal()

        def state_machine(memfa, memfb, machine_number):
            with m.FSM(init="Configuring"):
                with m.State("Configuring"):
                    m.d.sync += buffered_stream.ready.eq(0)
                    m.d.sync += memfa.write.valid.eq(0)
                    m.d.sync += memfb.write.valid.eq(0)

                    with m.If(self.generate_cubes):
                        with m.If(machine_number == 0):
                            m.next = "Clearing"
                        with m.Else():
                            m.next = "Stalling"

                with m.State("Clearing"):
                    m.d.sync += i.eq(i+1)
                    m.d.sync += buffered_stream.ready.eq(0)

                    m.d.sync += memfa.write.payload.data.eq(0)
                    m.d.sync += memfa.write.valid.eq(1)
                    m.d.sync += memfa.write.payload.addr.eq(i)

                    m.d.sync += memfb.write.payload.data.eq(0)
                    m.d.sync += memfb.write.valid.eq(1)
                    m.d.sync += memfb.write.payload.addr.eq(i)

                    with m.If(i == 1024):
                        m.d.sync += memfa.write.valid.eq(0)
                        m.d.sync += memfb.write.valid.eq(0)
                        m.next = "Counting"
                    
                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"
                    
                with m.State("Counting"):
                    m.d.sync += buffered_stream.ready.eq(1)
                    m.d.sync += memfa.write.valid.eq(0)
                    m.d.sync += memfb.write.valid.eq(0)
                    m.d.sync += memfb.write.payload.addr.eq(0)
                    m.d.sync += i.eq(i+1)

                    with m.If(buffered_stream.valid & buffered_stream.ready):
                        inc_bin = buffered_payload.bin
                        inc_phase = buffered_payload.phase

                        pixel = Signal(12)
                        muxer = Signal()
                        wavelength_cutoffs = Signal(signed(5*self.wavelength_cutoff_precision))
                        wavelength_bin = Signal(2)
                        not_within_bin = Signal()
                        divided_phase = Signal(signed(16))

                        m.d.sync += pixel_LUT.b.addr.eq(inc_bin)
                        m.d.sync += pixel_LUT.b.en.eq(1)
                        m.d.sync += wavelength_LUT.b.addr.eq(inc_bin)
                        m.d.sync += wavelength_LUT.b.en.eq(1)
                        
                        m.d.sync += divided_phase.eq(inc_phase>>(16-self.wavelength_cutoff_precision))

                        m.d.sync += buffered_stream.ready.eq(0)
                        m.d.sync += counting.eq(1)
                    
                    with m.If(counting):
                        m.d.sync += buffered_stream.ready.eq(0)

                        with m.FSM(init = "State0"):
                            with m.State("State0"):
                                with m.If(pixel_LUT.b.dread_valid & wavelength_LUT.b.dread_valid):
                                    m.d.sync += pixel.eq(pixel_LUT.b.dread)
                                    m.d.sync += wavelength_cutoffs.eq(wavelength_LUT.b.dread)

                                    m.d.sync += pixel_LUT.b.en.eq(0)
                                    m.d.sync += wavelength_LUT.b.en.eq(0)
                                    m.next = "State1"

                            with m.State("State1"):
                                def wavelength_cutoff(n):
                                    return wavelength_cutoffs[n*self.wavelength_cutoff_precision:(n+1)*self.wavelength_cutoff_precision].as_signed()

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

                                m.d.sync += memfa.read.payload.addr.eq(pixel[0:11])
                                m.d.sync += memfa.read.valid.eq(1)
                                m.d.sync += memfa.read_output.ready.eq(1)
                                m.next = "State2"

                            with m.State("State2"):
                                m.d.sync += muxer.eq(pixel[11])
                                m.d.sync += memfa.read.valid.eq(0)

                                with m.If(memfa.read_output.valid):
                                    m.d.sync += memfa.read_output.ready.eq(0)

                                    byte_array = Array([Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8)])
                                    for j in range(8):
                                        m.d.sync += byte_array[j].eq(memfa.read_output.payload.data[8*j:8*(j+1)])
                                    m.next = "State3"
                            
                            with m.State("State3"):                  
                                byte_array_new = Array([Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8),Signal(8)])
                                index = wavelength_bin | (muxer<<2)

                                for j in range(8):
                                    with m.If((j == index) & (byte_array[j] != 0b11111111) & (not_within_bin == 0)):
                                        m.d.comb += byte_array_new[j].eq((byte_array[j] + 1)[:8])
                                    with m.Elif((j == index) & (byte_array[j] == 0b11111111) & (not_within_bin == 0)):
                                        m.d.comb += byte_array_new[j].eq(byte_array[j])
                                        m.d.sync += self.count_overflow_flag.eq(1)
                                    with m.Else():
                                        m.d.comb += byte_array_new[j].eq(byte_array[j])

                                new_data = Cat(byte_array_new[j] for j in range(8))
                                m.d.sync += memfa.write.payload.data.eq(new_data)
                                m.d.sync += memfa.write.payload.addr.eq(pixel[0:11])
                                m.next = "State4"

                            with m.State("State4"):
                                m.d.sync += memfa.write.valid.eq(1)
                                m.next = "State5"

                            with m.State("State5"):
                                m.d.sync += memfa.write.valid.eq(0)
                                m.d.sync += counting.eq(0)
                                m.next = "State0"

                    with m.If(i >= self.cycles_per_frame-12):
                        m.d.sync += buffered_stream.ready.eq(0)

                    with m.If(i >= self.cycles_per_frame-1):
                        m.d.sync += i.eq(0)
                        m.d.sync += memfa.write.valid.eq(0)
                        m.next = "Stalling"

                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"

                with m.State("Stalling"):
                    m.d.sync += i.eq(i+1)
                    m.d.sync += memfb.write.valid.eq(0)

                    m.d.comb += [
                        memfb.read.payload.addr.eq(self.mem_read.payload.addr),
                        memfb.read.payload.user_data.last.eq(self.mem_read.payload.last),
                        memfb.read.payload.user_data.id.eq(self.mem_read.payload.id),
                        memfb.read.valid.eq(self.mem_read.valid),
                        self.mem_read.ready.eq(memfb.read.ready),

                        self.mem_read_output.payload.data.eq(memfb.read_output.payload.data),
                        self.mem_read_output.payload.mem_num.eq(machine_number),
                        self.mem_read_output.payload.last.eq(memfb.read_output.payload.user_data.last),
                        self.mem_read_output.payload.id.eq(memfb.read_output.payload.user_data.id),
                        self.mem_read_output.valid.eq(memfb.read_output.valid),
                        memfb.read_output.ready.eq(self.mem_read_output.ready),
                    ]

                    with m.If((self.mem_read.payload.mem_num != machine_number)):
                        m.d.comb += self.mem_read.ready.eq(0)
                        m.d.comb += memfb.read.valid.eq(0)

                    with m.If(i == self.cycles_per_frame - 1):
                        m.d.sync += i.eq(0)
                        m.next = "Clearing"
                
                    with m.If(~self.generate_cubes):
                        m.d.sync += i.eq(0)
                        m.next = "Configuring"


        #State machine memory 1
        state_machine(mem1fa, mem1fb, 0)
        
        #State machine memory 2
        state_machine(mem2fa, mem2fb, 1)
        
        
        return m
    
    