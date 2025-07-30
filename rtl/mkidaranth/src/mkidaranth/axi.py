from dataclasses import dataclass
from typing import Any, ClassVar
from amaranth.lib import stream, wiring, data
from amaranth.lib.enum import IntEnum, Flag
from amaranth.utils import exact_log2

# Inspired by https://stackoverflow.com/a/54489602
class AxiProperty:

    def __init__(self, allowed_values, default=None):
        self.allowed_values = allowed_values
        self.default = default

    def __set_name__(self, owner, name):
        self.name = name

    def __get__(self, instance, owner):
        if not instance:
            return self
        return instance.__dict__[self.name]

    def __delete__(self, instance):
        del instance.__dict__[self.name]

    def __set__(self, instance, value):
        if value is self:
            if self.default is not None:
                value = self.default
            else:
                raise ValueError(f"{self.name!r} is not optional!")
        if value not in self.allowed_values:
            raise ValueError(f"{self.name!r} should be one of {self.allowed_values!r}, not {value!r}")
        instance.__dict__[self.name] = value

class ReadWriteMode(Flag):
    READ_ONLY = 0x1
    WRITE_ONLY = 0x2
    READ_WRITE = 0x3

# Base class, should have all properties. Specializations should restrict property values
@dataclass(frozen=True)
class AxiProperties():
    READ_WRITE_MODE: ReadWriteMode = AxiProperty([ReadWriteMode.READ_ONLY, ReadWriteMode.WRITE_ONLY, ReadWriteMode.READ_WRITE], ReadWriteMode.READ_WRITE)

    ID_W_WIDTH: int = AxiProperty(range(33)) # Between 0 and 32
    ID_R_WIDTH: int = AxiProperty(range(33)) # Between 0 and 32

    # Write/read request
    ADDR_WIDTH: int = AxiProperty(range(1,65), 32) # Between 1 and 64
    REGION_Present: bool = AxiProperty([True, False], True)
    LEN_Present: bool = AxiProperty([True, False], True)
    SIZE_Present: bool = AxiProperty([True, False], True)
    BURST_Present: bool = AxiProperty([True, False], True)
    Exclusive_Accesses: bool = AxiProperty([True, False], True)
    CACHE_Present: bool = AxiProperty([True, False], True)
    PROT_Present: bool = AxiProperty([True, False], True)
    QOS_Present: bool = AxiProperty([True, False], True)

    # Write/read data
    DATA_WIDTH: int = AxiProperty([8, 16, 32, 64, 128, 256, 512, 1024])
    WSTRB_Present: bool = AxiProperty([True, False], True)
    WLAST_Present: bool = AxiProperty([True, False], True)
    RLAST_Present: bool = AxiProperty([True, False], True)

    # Write/read response
    BRESP_WIDTH: int = AxiProperty([0, 2, 3], 2)
    RRESP_WIDTH: int = AxiProperty([0, 2, 3], 2)


    # TODO: User signal width max value is only a recommendation, how to handle?
    USER_REQ_WIDTH: int = AxiProperty(range(129), 0)
    USER_DATA_WIDTH: int = AxiProperty(range(513), 0) # TODO: max DATA_WIDTH / 2
    USER_RESP_WIDTH: int = AxiProperty(range(17), 0)

    def __init__(self):
        raise NotImplementedError()

    MAX_BURST_LENGTH: ClassVar[int] = 256
    

@dataclass(frozen=True)
class Axi4Properties(AxiProperties):
    # Write/read response
    BRESP_WIDTH: int = AxiProperty([0, 2], 2)
    RRESP_WIDTH: int = AxiProperty([0, 2], 2)

@dataclass(frozen=True)
class Axi4LiteProperties(Axi4Properties):
    # Set default value to 0, since they're optional
    ID_W_WIDTH: int = AxiProperty(range(33), 0) # Between 0 and 32
    ID_R_WIDTH: int = AxiProperty(range(33), 0) # Between 0 and 32

    # Write/read request
    REGION_Present: bool = AxiProperty([False], False)
    LEN_Present: bool = AxiProperty([False], False)
    BURST_Present: bool = AxiProperty([False], False)
    SIZE_Present: bool = AxiProperty([False], False)
    Exclusive_Accesses: bool = AxiProperty([False], False)
    CACHE_Present: bool = AxiProperty([False], False)
    QOS_Present: bool = AxiProperty([False], False)

    # Write/read data
    DATA_WIDTH: int = AxiProperty([32, 64])
    WLAST_Present: bool = AxiProperty([False], False)
    RLAST_Present: bool = AxiProperty([False], False)

    # Constant, set to 1 because Lite doesn't have burst
    MAX_BURST_LENGTH: ClassVar[int] = 1

@dataclass(frozen=True)
class Axi5Properties(AxiProperties):
    # TODO: additional properties
    pass

@dataclass(frozen=True)
class Axi5LiteProperties(Axi5Properties):
    # Write/read request
    REGION_Present: bool = AxiProperty([False], False)
    LEN_Present: bool = AxiProperty([False], False)
    BURST_Present: bool = AxiProperty([False], False)
    Exclusive_Accesses: bool = AxiProperty([False], False)
    CACHE_Present: bool = AxiProperty([False], False)
    QOS_Present: bool = AxiProperty([False], False)

    # Write/read data
    WLAST_Present: bool = AxiProperty([False], False)
    RLAST_Present: bool = AxiProperty([False], False)

    # Constant, set to 1 because Lite doesn't have burst
    MAX_BURST_LENGTH: ClassVar[int] = 1


class BurstEncoding(IntEnum, shape=2):
    FIXED = 0x0
    INCR = 0x1
    WRAP = 0x2
    RES = 0x3

# Swapped order for allocate and other_allocate between read and write requests!
class WriteCacheEncoding(data.Struct):
    bufferable: 1
    modifiable: 1
    other_allocate: 1
    allocate: 1

class ReadCacheEncoding(data.Struct):
    bufferable: 1
    modifiable: 1
    allocate: 1
    other_allocate: 1

# Property names describe the active state
class ProtectionEncoding(data.Struct):
    privileged: 1
    non_secure: 1
    instruction: 1

class ResponseEncoding(IntEnum, shape=2):
    OKAY = 0x0
    EXOKAY = 0x1
    SLVERR = 0x2
    DECERR = 0x3

# TODO: remove duplication
class ExtendedWriteResponseEncoding(IntEnum, shape=3):
    OKAY = 0x0
    EXOKAY = 0x1
    SLVERR = 0x2
    DECERR = 0x3
    DEFER = 0x4
    TRANSFAULT = 0x5
    RESERVED = 0x6
    UNSUPPORTED = 0x7

# TODO: remove duplication
class ExtendedReadResponseEncoding(IntEnum, shape=3):
    OKAY = 0x0
    EXOKAY = 0x1
    SLVERR = 0x2
    DECERR = 0x3
    PREFETCHED = 0x4
    TRANSFAULT = 0x5
    OKAYDIRTY = 0x6
    RESERVED = 0x7


class Channel(data.StructLayout):

    def __init__(self, signals: dict[str, tuple[Any, Any]]):
        """
        signals: dictionary, keys represent port names and the values are shape, init tuples
        """

        members = {signal: width for signal, (width, init) in signals.items() if width}
        
        super().__init__(members)

        self.INIT = self.const({signal: init for signal, (width, init) in signals.items() if width})

class WriteRequestChannel(Channel):

    def __init__(self, axi_props: AxiProperties):
        # Dict: port name -> (width, init)
        members = {
            "addr": (axi_props.ADDR_WIDTH, 0),
            "id": (axi_props.ID_W_WIDTH, 0),
            "region": (4 if axi_props.REGION_Present else 0, 0),
            "len": (8 if axi_props.LEN_Present else 0, 0),
            "size": (3 if axi_props.SIZE_Present else 0, exact_log2(axi_props.DATA_WIDTH // 8)),
            "burst": (BurstEncoding if axi_props.BURST_Present else 0, BurstEncoding.INCR),
            "lock": (1 if axi_props.Exclusive_Accesses else 0, 0),
            "cache": (WriteCacheEncoding if axi_props.CACHE_Present else 0, 0),
            "prot": (ProtectionEncoding if axi_props.PROT_Present else 0, 0),
            "qos": (4 if axi_props.QOS_Present else 0, 0),
            "user": (axi_props.USER_REQ_WIDTH, 0),
        }

        super().__init__(members)

class WriteDataChannel(Channel):

    def __init__(self, axi_props: AxiProperties):
        members = {
            "data": (axi_props.DATA_WIDTH, 0),
            "last": (1 if axi_props.WLAST_Present else 0, 1),
            # TODO: Init value of -1 doesn't work?
            "strb": (axi_props.DATA_WIDTH // 8 if axi_props.WSTRB_Present else 0, 2**(axi_props.DATA_WIDTH // 8) - 1),
            "user": (axi_props.USER_DATA_WIDTH, 0),
        }

        super().__init__(members)

class WriteResponseChannel(Channel):

    def __init__(self, axi_props: AxiProperties):
        def resp_shape():
            match axi_props.BRESP_WIDTH:
                case 0:
                    return 0
                case 2:
                    return ResponseEncoding
                case 3:
                    return ExtendedWriteResponseEncoding
                case _:
                    raise ValueError(f"Invalid response width {axi_props.BRESP_WIDTH}")

        members = {
            "resp": (resp_shape(), ResponseEncoding.OKAY),
            "id": (axi_props.ID_W_WIDTH, 0),
            "user": (axi_props.USER_RESP_WIDTH, 0),
        }

        super().__init__(members)

class ReadRequestChannel(Channel):

    def __init__(self, axi_props: AxiProperties):
        # Dict: port name -> (width, init)
        members = {
            "addr": (axi_props.ADDR_WIDTH, 0),
            "id": (axi_props.ID_R_WIDTH, 0),
            "region": (4 if axi_props.REGION_Present else 0, 0),
            "len": (8 if axi_props.LEN_Present else 0, 0),
            "size": (3 if axi_props.SIZE_Present else 0, exact_log2(axi_props.DATA_WIDTH // 8)),
            "burst": (BurstEncoding if axi_props.BURST_Present else 0, BurstEncoding.INCR),
            "lock": (1 if axi_props.Exclusive_Accesses else 0, 0),
            "cache": (ReadCacheEncoding if axi_props.CACHE_Present else 0, 0),
            "prot": (ProtectionEncoding if axi_props.PROT_Present else 0, 0),
            "qos": (4 if axi_props.QOS_Present else 0, 0),
            "user": (axi_props.USER_REQ_WIDTH, 0),
        }

        super().__init__(members)

class ReadDataChannel(Channel):

    def __init__(self, axi_props: AxiProperties):
        def resp_shape():
            match axi_props.RRESP_WIDTH:
                case 0:
                    return 0
                case 2:
                    return ResponseEncoding
                case 3:
                    return ExtendedReadResponseEncoding
                case _:
                    raise ValueError(f"Invalid response width {axi_props.RRESP_WIDTH}")

        members = {
            "resp": (resp_shape(), ResponseEncoding.OKAY),
            "data": (axi_props.DATA_WIDTH, 0),
            "id": (axi_props.ID_R_WIDTH, 0),
            "last": (1 if axi_props.RLAST_Present else 0, 1),
            "user": (axi_props.USER_DATA_WIDTH + axi_props.USER_RESP_WIDTH, 0),
        }

        super().__init__(members)


class Signature(wiring.Signature):
    
    def __init__(self, axi_props: AxiProperties):
        self.props = axi_props

        channels = dict()

        if axi_props.READ_WRITE_MODE & ReadWriteMode.READ_ONLY:
            channels["ar"] = (wiring.Out, ReadRequestChannel(axi_props))
            channels["r"] = (wiring.In, ReadDataChannel(axi_props))

        if axi_props.READ_WRITE_MODE & ReadWriteMode.WRITE_ONLY:
            channels["aw"] = (wiring.Out, WriteRequestChannel(axi_props))
            channels["w"] = (wiring.Out, WriteDataChannel(axi_props))
            channels["b"] = (wiring.In, WriteResponseChannel(axi_props))

        super().__init__({
            name: flow(stream.Signature(shape, payload_init=shape.INIT)) for name, (flow, shape) in channels.items()
        })


if __name__ == "__main__":
    from amaranth.back import verilog
    from amaranth import Module

    props = Axi4LiteProperties(
        DATA_WIDTH=32
    )
    print(props)

    class Test(wiring.Component):
        input: wiring.Out(Signature(props))
        #output: wiring.Out(Signature(Axi5LiteProperties()))

        def elaborate(self, platform):
            m = Module()
            return m

    from amaranth.back import verilog
    print(verilog.convert(Test()))