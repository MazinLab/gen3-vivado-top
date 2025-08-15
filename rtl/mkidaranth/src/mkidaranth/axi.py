from dataclasses import dataclass
from typing import Any, ClassVar
from amaranth import Module
from amaranth.lib import stream, wiring, data
from amaranth.lib.enum import IntEnum, Flag
from amaranth.utils import exact_log2

from .trigger import StreamPipelineStage

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

class AxiPipelineStage(wiring.Component):
    def __init__(self, axi_props: AxiProperties):
        self.props = axi_props
        super().__init__({
            "input": wiring.In(Signature(self.props)),
            "output": wiring.Out(Signature(self.props)),
        })

    def elaborate(self, platform):
        m = Module()
        if self.props.READ_WRITE_MODE & ReadWriteMode.READ_ONLY:
            m.submodules.arpipe = arpipe = StreamPipelineStage(ReadRequestChannel(self.props), payload_init=ReadRequestChannel(self.props).INIT)
            wiring.connect(m, wiring.flipped(self.input.ar), arpipe.input) 
            wiring.connect(m, arpipe.output, wiring.flipped(self.output.ar))

            m.submodules.rpipe = rpipe = StreamPipelineStage(ReadDataChannel(self.props), payload_init=ReadDataChannel(self.props).INIT)
            wiring.connect(m, wiring.flipped(self.input.r), rpipe.output) 
            wiring.connect(m, rpipe.input, wiring.flipped(self.output.r))

        if self.props.READ_WRITE_MODE & ReadWriteMode.WRITE_ONLY:
            m.submodules.awpipe = awpipe = StreamPipelineStage(WriteRequestChannel(self.props), payload_init=WriteRequestChannel(self.props).INIT)
            wiring.connect(m, wiring.flipped(self.input.aw), awpipe.input) 
            wiring.connect(m, awpipe.output, wiring.flipped(self.output.aw))

            m.submodules.wpipe = wpipe = StreamPipelineStage(WriteDataChannel(self.props), payload_init=WriteDataChannel(self.props).INIT)
            wiring.connect(m, wiring.flipped(self.input.w), wpipe.input) 
            wiring.connect(m, wpipe.output, wiring.flipped(self.output.w))

            m.submodules.rpipe = bpipe = StreamPipelineStage(WriteResponseChannel(self.props), payload_init=WriteResponseChannel(self.props).INIT)
            wiring.connect(m, wiring.flipped(self.input.b), bpipe.output) 
            wiring.connect(m, bpipe.input, wiring.flipped(self.output.b))

        return m

class StandardizedSignature(wiring.Signature):
    def __init__(self, base_signature, data_field = None, prefix = "t", renames = {}):
        self._base_signature = base_signature
        self._data_field = data_field
        self._prefix = prefix
        self._renames = renames

        config_dict = {}
        config_dict[f"{prefix}valid"] = wiring.Out(1)
        config_dict[f"{prefix}ready"] = wiring.In(1)

        if data_field is None:
            shape = base_signature.members['payload'].shape
            if shape is int:
                size = shape
            else:
                size = shape.size
            config_dict[f"{prefix}data"] = wiring.Out(size)
        else:
            shape = base_signature.members['payload'].shape
            for k, v in shape:
                size = v.width
                if k == data_field:
                    k = "data"
                if k in renames.keys():
                    k = renames[k]
                config_dict[f"{prefix}{k}"] = wiring.Out(size)

        super().__init__(config_dict)

class StandardizedAxiSignature(wiring.Signature):
    def __init__(self, axi_props):
        self.props = axi_props

        channels = dict()

        if axi_props.READ_WRITE_MODE & ReadWriteMode.READ_ONLY:
            channels["ar"] = (False, ReadRequestChannel(axi_props))
            channels["r"] = (True, ReadDataChannel(axi_props))

        if axi_props.READ_WRITE_MODE & ReadWriteMode.WRITE_ONLY:
            channels["aw"] = (False, WriteRequestChannel(axi_props))
            channels["w"] = (False, WriteDataChannel(axi_props))
            channels["b"] = (True, WriteResponseChannel(axi_props))

        sig = {}
        self._stream_signatures = {}
        for name, (flip, shape) in channels.items():
            self._stream_signatures[name] = stream_sig = StandardizedSignature(stream.Signature(shape, payload_init=shape.INIT), prefix=name, data_field=False)
            for signame, innershape in stream_sig.members.items():
                if flip:
                    sig[signame] = innershape.flip()
                else:
                    sig[signame] = innershape

        super().__init__(sig)

def connect(m, a, b, signature_override=None, required_signature=StandardizedSignature, double_flip=False):
    flipped = False
    standard = a
    amaranth = b
    if type(a.signature) is wiring.FlippedSignature:
        if type(wiring.flipped(a).signature) is required_signature:
            flipped = True
    elif type(a.signature) is required_signature:
        signature = a.signature
    else:
        standard = b
        amaranth = a
        if type(b.signature) is wiring.FlippedSignature:
            if type(wiring.flipped(b).signature) is required_signature:
                flipped = True
        elif type(b.signature) is required_signature:
            pass
        else:
            assert False
    if double_flip:
        flipped = not flipped
    signature = standard.signature
    if signature_override is not None:
        signature = signature_override
    base_signature = signature._base_signature
    data_field = signature._data_field
    prefix = signature._prefix
    renames = signature._renames
    if not flipped:
        m.d.comb += amaranth.valid.eq(getattr(standard, f'{prefix}valid'))
        m.d.comb += getattr(standard, f'{prefix}ready').eq(amaranth.ready)

        if data_field is None:
            m.d.comb += amaranth.payload.eq(getattr(standard, f'{prefix}data'))
        else:
            shape = base_signature.members['payload'].shape
            for k, _ in shape:
                if k == data_field:
                    kp = "data"
                elif k in renames.keys():
                    kp = renames[k]
                else:
                    kp = k
                m.d.comb += getattr(amaranth.payload, k).eq(getattr(standard, f'{prefix}{kp}'))
    else:
        m.d.comb += getattr(standard, f'{prefix}valid').eq(amaranth.valid)
        m.d.comb += amaranth.ready.eq(getattr(standard, f'{prefix}ready'))

        if data_field is None:
            m.d.comb += getattr(standard, f'{prefix}data').eq(amaranth.payload)
        else:
            shape = base_signature.members['payload'].shape
            for k, _ in shape:
                if k == data_field:
                    kp = "data"
                elif k in renames.keys():
                    kp = renames[k]
                else:
                    kp = k
                m.d.comb += getattr(standard, f'{prefix}{kp}').eq(getattr(amaranth.payload, k))

def connect_axi(m, a, b):
    if type(a.signature) is StandardizedAxiSignature:
        sig = a.signature
        standard = a
        amaranth = b
    elif type(wiring.flipped(a).signature) is StandardizedAxiSignature:
        sig = wiring.flipped(a).signature
        standard = a
        amaranth = b
    elif type(b.signature) is StandardizedAxiSignature:
        sig = b.signature
        standard = b
        amaranth = a
    elif type(wiring.flipped(b).signature) is StandardizedAxiSignature:
        sig = wiring.flipped(b).signature
        standard = b
        amaranth = a
    else:
        assert False
    for name, stream_sig in sig._stream_signatures.items():
        connect(
            m,
            standard,
            getattr(amaranth, name),
            signature_override=stream_sig,
            required_signature=StandardizedAxiSignature,
            double_flip = name in ["r", "b"]
        )
