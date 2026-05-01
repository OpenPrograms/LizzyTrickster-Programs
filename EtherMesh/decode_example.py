#!/usr/bin/env python

import struct
from enum import IntEnum

class ArgType(IntEnum):
    STRING = 1
    NUMBER = 2
    BOOLEAN = 3
    NIL = 4

def decodePacket(self, dataline: bytes): # dataline here is a bytestring sent or received by EtherMesh WITHOUT the length prefix
    saddr: bytes # Type hinting
    daddr: bytes
    pack_port: int
    argstr_length: int
    argstr_segcount: int
    try:
        pType, saddr, daddr, pack_port, argstr_length, argstr_segcount = struct.unpack_from("<B 36s 36s H H B", dataline)
        self.logger.debug(f"{pType=} {saddr=} {daddr=} {pack_port=} {argstr_length=} {argstr_segcount=}")
        offset = struct.calcsize("< B 36s 36s H H B")
        args: list = list()
        for _ in range(argstr_segcount):
            argType: int = struct.unpack_from("<B", dataline, offset=offset)[0]
            offset = offset + struct.calcsize("<B")
            match argType:
                case ArgType.STRING:
                    length: int = struct.unpack_from("<H", dataline, offset = offset)[0] # H is 2 bytes
                    offset = offset + struct.calcsize("<H")
                    args.append( struct.unpack_from(f"{length}s", dataline, offset=offset)[0] )
                    offset = offset + struct.calcsize(f"{length}s")
                case ArgType.NUMBER:
                    args.append( struct.unpack_from("<d", dataline, offset=offset)[0] ) # Lua number 
                    offset = offset + struct.calcsize("<d")
                case ArgType.BOOLEAN:
                    args.append( bool(struct.unpack_from("<B", dataline, offset= offset)[0]) )
                    offset = offset+struct.calcsize("<B")
                case ArgType.NIL: # nil / None
                    args.append(None)
                    offset = offset+struct.calcsize("<x")
        self.logger.debug(f"after:: {saddr=} {daddr=} {pack_port=} {argstr_length=} {argstr_segcount=} :: {args=}")
    except:
        self.logger.exception("oh nyoo")
