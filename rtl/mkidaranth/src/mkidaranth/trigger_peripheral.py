from amaranth import *

from amaranth.lib import wiring, stream, data
from amaranth.lib.wiring import In, Out
from amaranth_soc import csr

from .trigger import TriggerState, trigger_config, timestamp


class Trigger(wiring.Component):
    class ChunkSample(csr.Register, access="r"):
        timestamp: csr.Field(csr.action.R, timestamp)
        cycle: csr.Field(csr.action.R, 52)
        read: csr.Field(csr.action.R, 2)
        dropped: csr.Field(csr.action.R, 1)
