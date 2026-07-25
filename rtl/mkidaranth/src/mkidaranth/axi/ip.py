from amaranth import *
from amaranth.lib import wiring, fifo, stream
from amaranth.lib.wiring import In, Out
from amaranth.utils import exact_log2

from amaranth_soc import csr

from . import bus

# Heavily pipelined to let vivado retime a bit
class AXICSRBridge(wiring.Component):
    def __init__(self, *, addr_width, data_width=32):
        self._dw = data_width
        self._aw = addr_width
        self._caw = addr_width - exact_log2(data_width // 8)
        self.axi_properties = bus.Axi4LiteProperties(DATA_WIDTH=data_width, ADDR_WIDTH=addr_width)
        self.csr_signature = csr.Signature(addr_width=self._caw, data_width=data_width)

        super().__init__({
            "axi": In(bus.Signature(self.axi_properties)),
            "csr": Out(self.csr_signature),
        })

    def elaborate(self, platform):
        m = Module()

        m.d.sync += self.csr.w_data.eq(self.axi.w.payload.data)

        alatch = Signal(self._caw)

        with m.FSM():
            with m.State("WAITING_ADDRESS"):
                with m.If(self.axi.aw.valid):
                    m.d.comb += self.axi.aw.ready.eq(1)
                    m.d.sync += alatch.eq(self.axi.aw.payload.addr.shift_right(self._aw - self._caw))
                    m.next = "WRITE"
                with m.Elif(self.axi.ar.valid):
                    m.d.comb += self.axi.ar.ready.eq(1)
                    m.d.sync += alatch.eq(self.axi.ar.payload.addr.shift_right(self._aw - self._caw))
                    m.next = "READ-1"

            with m.State("WRITE"):
                m.d.sync += self.csr.addr.eq(alatch)
                with m.If(self.axi.w.valid):
                    m.d.comb += self.axi.w.ready.eq(1)
                    m.d.sync += self.csr.w_stb.eq(1)
                    m.next = "WRITE_RESP"

            with m.State("WRITE_RESP"):
                m.d.sync += self.csr.w_stb.eq(0)
                m.d.comb += self.axi.b.valid.eq(1)
                with m.If(self.axi.b.valid & self.axi.b.ready):
                    m.next = "WAITING_ADDRESS"

            with m.State("READ-1"):
                m.d.sync += [
                    self.csr.addr.eq(alatch),
                    self.csr.r_stb.eq(1)
                ]
                m.next = "READ-2"

            with m.State("READ-2"):
                m.d.sync += [
                    self.csr.r_stb.eq(0),
                ]
                m.next = "READ-3"
            with m.State("READ-3"):
                m.d.sync += [
                    self.axi.r.payload.data.eq(self.csr.r_data),
                    self.axi.r.valid.eq(1),
                ]
                m.next = "READ-4"
            with m.State("READ-4"):
                with m.If(self.axi.r.valid & self.axi.r.ready):
                    m.d.sync += self.axi.r.valid.eq(0)
                    m.next = "WAITING_ADDRESS"

        return m


class AXIDMA(wiring.Component):
    class AddressFIFO(csr.Register, access="rw"):
        def __init__(self, addr_width):
            super().__init__({
                # Must be on a 4k boundary
                "address": csr.Field(csr.action.W, addr_width),
                "depth": csr.Field(csr.action.R, 8),
                "count": csr.Field(csr.action.R, 8),
                "lowmark": csr.Field(csr.action.RW, 8),
            })

    class DMAControl(csr.Register, access="rw"):
        # Must be a multiple of burst_length_bytes
        buffer_size: csr.Field(csr.action.RW, 24)
        flush: csr.Field(csr.action.RW, 1)
        fault: csr.Field(csr.action.R, 1)

    class InputFIFO(csr.Register, access="rw"):
        depth: csr.Field(csr.action.R, 16)
        count: csr.Field(csr.action.R, 16)
        tx_threshold: csr.Field(csr.action.RW, 16)

    class DebugReg(csr.Register, access="r"):
        def __init__(self, addr_width):
            super().__init__({
                "n": csr.Field(csr.action.R, 12),
                "fault": csr.Field(csr.action.R, 1),
                "data_wait": csr.Field(csr.action.R, 1),
                "address_wait": csr.Field(csr.action.R, 1),
                "address_channel": csr.Field(csr.action.R, 1),
                "writing": csr.Field(csr.action.R, 1),
                "data_wait_mid": csr.Field(csr.action.R, 1),
                "last_resp": csr.Field(csr.action.R, bus.ExtendedWriteResponseEncoding),
                "burst_count": csr.Field(csr.action.R, 16),
                "xfer_count": csr.Field(csr.action.R, 16),
            })

    def __init__(self, *,
        burst_length, input_fifo,
        addr_width=48, data_width=128, id = 0, id_width=6,
        address_depth=8, ctl_data_width=64, debug_reg=True
    ):
        assert address_depth < 256
        assert burst_length >= 4
        self.addr_width = addr_width
        self.data_width = data_width
        self.address_depth = address_depth
        self.id = id
        self.burst_length = burst_length
        self._bpt = data_width // 8
        self._burst_length_bytes = self.burst_length * self._bpt
        self._burst_bits = exact_log2(self._burst_length_bytes)
        assert exact_log2(self._bpt) <= 0b111

        self.debug_reg = debug_reg
        self.input_fifo = input_fifo

        # Per the AXI4 spec bursts must not cross a 4K boundary, low key it
        # it would probably be fine in the year of our lord 2024
        #
        # Scratch that being less than 4k simplifies so many things holy shit
        assert 4096 % self._burst_length_bytes == 0
        assert self._burst_length_bytes <= 4096

        regs = csr.Builder(addr_width=8, data_width=ctl_data_width)
        self._afifo = regs.add(
            "AddressFIFO", self.AddressFIFO(addr_width)
        )
        self._dmactl = regs.add("DMAControl", self.DMAControl())
        if self.input_fifo:
            self._input_fifo_reg = regs.add("InputFIFO", self.InputFIFO())
        if self.debug_reg:
            self._debug_reg = regs.add("Debug", self.DebugReg(self.addr_width))

        self._bridge = csr.Bridge(regs.as_memory_map())

        self.dma_bus_signature = bus.Signature(bus.Axi4Properties(
            READ_WRITE_MODE=bus.ReadWriteMode.WRITE_ONLY,
            ADDR_WIDTH=addr_width,
            DATA_WIDTH=data_width,
            ID_W_WIDTH=id_width,
            ID_R_WIDTH=0,
            WSTRB_Present=True,
            WLAST_Present=True,
            QOS_Present=False,
            PROT_Present=False,
            CACHE_Present=False,
            Exclusive_Accesses=False,
            REGION_Present=False,
        ))

        super().__init__(
            {
                "ctlbus": In(csr.Signature(addr_width=8, data_width=ctl_data_width)),
                "dmabus": Out(self.dma_bus_signature),
                "stream": In(stream.Signature(data_width)),
                "int": Out(1),
                "fault": Out(1),
            }
        )

        self.ctlbus.memory_map = self._bridge.bus.memory_map

    def elaborate(self, platform):
        m = Module()

        m.submodules.bridge = self._bridge
        wiring.connect(m, wiring.flipped(self.ctlbus), self._bridge.bus)

        # Address FIFO <-> Bus interaction
        m.submodules.address_fifo = address_fifo = fifo.SyncFIFOBuffered(
            width=self.addr_width, depth=self.address_depth
        )
        m.d.comb += [
            address_fifo.w_data.eq(self._afifo.f.address.w_data),
            address_fifo.w_en.eq(self._afifo.f.address.w_stb),
            self._afifo.f.depth.r_data.eq(self.address_depth),
            self._afifo.f.count.r_data.eq(address_fifo.level),
            self.int.eq(address_fifo.level < self._afifo.f.lowmark.data),
        ]

        # Input FIFO Management
        if self.input_fifo:
            m.submodules.input_fifo = ififo = fifo.SyncFIFOBuffered(
                width=self.data_width, depth=self.input_fifo
            )
            wiring.connect(m, wiring.flipped(self.stream), ififo.w_stream)
            m.d.sync += self._input_fifo_reg.f.count.r_data.eq(ififo.level)
            m.d.comb += self._input_fifo_reg.f.depth.r_data.eq(Const(self.input_fifo))
            input_stream = ififo.r_stream
        else:
            input_stream = self.stream

        # Actual DMA Logic
        n = Signal(range(self.burst_length))
        clatch = Signal()

        # Basic AXI transaction manaogement
        address_latch = Signal(self.addr_width - self._burst_bits)
        stop_addr = Signal(self.addr_width - self._burst_bits)
        m.d.comb += [
            self.dmabus.aw.payload.burst.eq(bus.BurstEncoding.INCR),
            self.dmabus.aw.payload.size.eq(exact_log2(self._bpt)),
            self.dmabus.aw.payload.len.eq(self.burst_length - 1),
            self.dmabus.b.ready.eq(1),
            self.dmabus.aw.payload.addr.eq(address_latch.shift_left(self._burst_bits)),
            self.dmabus.aw.payload.id.eq(Const(self.id)),
            self.dmabus.w.payload.data.eq(input_stream.payload),
            self.dmabus.w.payload.strb.eq(-1),
            self.dmabus.w.valid.eq(0),
            self.dmabus.w.payload.last.eq(n == self.burst_length - 1),
            input_stream.ready.eq(0),
        ]

        with m.FSM() as fsm:
            with m.State("Data Wait"):
                if self.input_fifo:
                    m.d.sync += clatch.eq(ififo.level >= self._input_fifo_reg.f.tx_threshold.data)
                    with m.If(input_stream.valid & clatch):
                        m.d.sync += address_fifo.r_stream.ready.eq(1)
                        m.d.sync += clatch.eq(0)
                        m.next = "Address Wait"
                else:
                    with m.If(input_stream.valid):
                        m.d.sync += address_fifo.r_stream.ready.eq(1)
                        m.next = "Address Wait"
            with m.State("Address Wait"):
                with m.If(address_fifo.r_stream.ready & address_fifo.r_stream.valid):
                    m.d.sync += address_fifo.r_stream.ready.eq(0)
                    m.d.sync += address_latch.eq(address_fifo.r_stream.payload.shift_right(self._burst_bits))
                    m.d.sync += stop_addr.eq(
                        address_fifo.r_stream.payload.shift_right(self._burst_bits)
                        + self._dmactl.f.buffer_size.data.shift_right(self._burst_bits)
                    )
                    m.d.sync += self.dmabus.aw.valid.eq(1)
                    m.next = "Address Channel"
            with m.State("Address Channel"):
                m.d.sync += n.eq(0)
                with m.If(self.dmabus.aw.ready & self.dmabus.aw.valid):
                    m.d.sync += self.dmabus.aw.valid.eq(0)
                    m.d.sync += address_latch.eq(address_latch + 1)
                    m.next = "Writing"
            with m.State("Writing"):
                m.d.comb += [
                    self.dmabus.w.valid.eq(input_stream.valid),
                    input_stream.ready.eq(self.dmabus.w.ready),
                ]
                with m.If(self.dmabus.w.valid & self.dmabus.w.ready):
                    m.d.sync += n.eq(n + 1)
                    with m.If((n == self.burst_length - 1) & (address_latch == stop_addr)):
                        if self.debug_reg:
                            m.d.sync += self._debug_reg.f.burst_count.r_data.eq(self._debug_reg.f.burst_count.r_data + 1)
                            m.d.sync += self._debug_reg.f.xfer_count.r_data.eq(self._debug_reg.f.xfer_count.r_data + 1)
                        if self.input_fifo:
                            m.next = "Data Wait"
                        else:
                            with m.If(input_stream.valid):
                                m.d.sync += address_fifo.r_stream.ready.eq(1)
                                m.next = "Address Wait"
                            with m.Else():
                                m.next = "Data Wait"
                    with m.Elif(n == self.burst_length - 1):
                        if self.debug_reg:
                            m.d.sync += self._debug_reg.f.burst_count.r_data.eq(self._debug_reg.f.burst_count.r_data + 1)
                        if self.input_fifo:
                            m.next = "Data Wait Mid"
                        else:
                            with m.If(input_stream.valid):
                                m.d.sync += self.dmabus.aw.valid.eq(1)
                                m.next = "Address Channel"
                            with m.Else():
                                m.next = "Data Wait Mid"
            with m.State("Data Wait Mid"):
                if self.input_fifo:
                    m.d.sync += clatch.eq(ififo.level >= self._input_fifo_reg.f.tx_threshold.data)
                    with m.If(input_stream.valid & clatch):
                        m.d.sync += self.dmabus.aw.valid.eq(1)
                        m.d.sync += clatch.eq(0)
                        m.next = "Address Channel"
                else:
                    with m.If(input_stream.valid):
                        m.d.sync += self.dmabus.aw.valid.eq(1)
                        m.next = "Address Channel"

        with m.If(self.dmabus.b.valid & self.dmabus.b.ready):
            with m.If(self.dmabus.b.payload.resp > 1):
                m.d.sync += self.fault.eq(1)

        if self.debug_reg:
            m.d.sync += [
                self._debug_reg.f.n.r_data.eq(n),
                self._debug_reg.f.fault.r_data.eq(self.fault),
                self._debug_reg.f.data_wait.r_data.eq(fsm.ongoing("Data Wait")),
                self._debug_reg.f.address_wait.r_data.eq(fsm.ongoing("Address Wait")),
                self._debug_reg.f.address_channel.r_data.eq(fsm.ongoing("Address Channel")),
                self._debug_reg.f.writing.r_data.eq(fsm.ongoing("Writing")),
                self._debug_reg.f.data_wait_mid.r_data.eq(fsm.ongoing("Data Wait Mid")),
            ]
            with m.If(self.dmabus.b.valid & self.dmabus.b.ready):
                m.d.sync += self._debug_reg.f.last_resp.r_data.eq(self.dmabus.b.payload.resp)

        return m
