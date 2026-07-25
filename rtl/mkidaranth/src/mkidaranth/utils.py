from amaranth import *
from amaranth.lib import wiring, data, stream
from amaranth.lib.wiring import In, Out
from amaranth.vendor import XilinxPlatform

__all__ = ["Complex", "CMultiply"]

class RFSoCGen3Platform(XilinxPlatform):
    device = "xczu48dr"
    package = "ffvg1517"
    speed = "2"
    resources = []
    connectors = []

class Complex(data.StructLayout):
    def __init__(self, bits):
        super().__init__({"real": signed(bits), "imag": signed(bits)})

# Ripped pretty much directly from UG901
class CMultiply(wiring.Component):
    def __init__(self, a_width, b_width):
        self.__a_width = a_width
        self.__b_width = b_width
        super().__init__({
            "a": In(stream.Signature(Complex(a_width), always_ready=True)),
            "b": In(stream.Signature(Complex(b_width), always_ready=True)),
            "p": Out(stream.Signature(Complex(a_width + b_width + 1), always_ready=True)),
        })

    def elaborate(self, platform):
        m = Module()
        a_delay = [Signal(Complex(self.__a_width)) for _ in range(4)]
        b_delay = [Signal(Complex(self.__b_width)) for _ in range(4)]
        v_delay = [Signal(1) for _ in range(5)]

        m.d.sync += (
            [
                a_delay[0].eq(self.a.payload),
                b_delay[0].eq(self.b.payload),
                v_delay[0].eq(self.a.valid & self.b.valid),
            ]
            + [a_delay[i].eq(a_delay[i - 1]) for i in range(1, 4)]
            + [b_delay[i].eq(b_delay[i - 1]) for i in range(1, 4)]
            + [v_delay[i].eq(v_delay[i - 1]) for i in range(1, 5)]
        )

        # Common Product
        add_common_1 = Signal(signed(self.__a_width + 1))
        mult_common_2 = Signal(signed(self.__a_width + self.__b_width + 1))
        mult_common_3 = Signal(signed(self.__a_width + self.__b_width + 1))
        mult_common_4 = Signal(signed(self.__a_width + self.__b_width + 1))
        m.d.sync += [
            add_common_1.eq(a_delay[0].real - a_delay[0].imag),
            mult_common_2.eq(add_common_1 * b_delay[1].imag),
            mult_common_3.eq(mult_common_2),
            mult_common_4.eq(mult_common_3),
        ]

        # Real Part
        add_real_3 = Signal(signed(self.__b_width + 1))
        mult_real_4 = Signal(signed(self.__a_width + self.__b_width + 1))
        m.d.sync += [
            add_real_3.eq(b_delay[2].real - b_delay[2].imag),
            mult_real_4.eq(add_real_3 * a_delay[3].real),
        ]

        # Imaginary Part
        add_imag_3 = Signal(signed(self.__b_width + 1))
        mult_imag_4 = Signal(signed(self.__a_width + self.__b_width + 1))
        m.d.sync += [
            add_imag_3.eq(b_delay[2].real + b_delay[2].imag),
            mult_imag_4.eq(add_imag_3*a_delay[3].imag)
        ]

        # Output
        m.d.sync += [
            self.p.payload.real.eq(mult_real_4 + mult_common_4),
            self.p.payload.imag.eq(mult_imag_4 + mult_common_4),
            self.p.valid.eq(v_delay[4]),
        ]
        return m
