import asyncio
import logging
import coloredlogs
import copy
import struct
from enum import IntEnum

#logging.basicConfig(level=logging.DEBUG)
log_format = "%(asctime)s %(name)s %(levelname)s %(message)s"
fstyles = coloredlogs.DEFAULT_FIELD_STYLES | {'levelname':dict(bold=True, color="cyan")}
coloredlogs.install(level=logging.DEBUG, fmt=log_format, field_styles = fstyles)

def getPacketType(bytestr: bytes) -> int:
    return struct.unpack_from("<B", bytestr)[0]

class PacketType(IntEnum):
    KA = 1
    HE = 2
    PO = 3
    PC = 4
    DA = 5


class Client:
    def __init__(self, Manager: 'ClientManager', reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        self.Manager = Manager
        self.client_addr = writer.get_extra_info('peername')
        self.reader: asyncio.StreamReader = reader
        self.writer: asyncio.StreamWriter = writer
        self.outqueue: asyncio.Queue[bytes] = asyncio.Queue()
        self.tasks: set[asyncio.Task] = set()
        self.addr: bytes = b"UNKNOWN"
        self.ports: set[int] = set()
        self.closed: bool = False
        self.logger.info("New client!")

    @property
    def logger(self) -> logging.Logger:
        return logging.getLogger(f"Client.{self.addr.decode('UTF-8')}@{self.client_addr[0]}#{self.client_addr[1]}")
    
    async def start(self):
        self.tasks.add(asyncio.create_task(self.read_loop()))
        self.tasks.add(asyncio.create_task(self.write_loop()))
        self.tasks.add(asyncio.create_task(self.check_loop()))

    async def close(self):
        self.logger.warning("CLOSING")
        try:
            for task in self.tasks:
                task.cancel()
        except:
            self.logger.exception("Failed to cancel tasks?")
        self.closed = True

    def __str__(self):
        return f"<Client {[self.client_addr, self.addr, self.closed]}>"

    async def check_loop(self):
        do_we_have_client: bool = False
        for i in range(5):
            await asyncio.sleep(10)
            if self.addr != b"UNKNOWN":
                do_we_have_client = True
                break
            self.logger.warning("Don't know client's address yet")
        if do_we_have_client == False:
            self.logger.warning("Couldn't determine client's address, closing")
            await self.close()

    async def read_loop(self):
        buffer = bytes()
        while True:
            try:
                data: bytes = await self.reader.read(4096)
                if len(data) == 0:
                    self.logger.info("Lost client")
                    await self.close()
                    break # read() blocks until there is data, if it returns 0, we lost the client and might as well stop processing packets
                buffer = buffer + data
                packetLength: int = struct.unpack_from("<H", buffer)[0] # 2 bytes
                self.logger.debug( f"Inbound packet length is {packetLength}" )
                if len(buffer) + 2 < packetLength: # If the buffer is less than a full packet
                    continue
                packet: bytes = buffer[2:packetLength + 2] # Discard the 2 bytes at the start that specify the length, get until the end of the packet + the length
                await self.process_packet( packet )
                buffer = buffer[packetLength + 2 :] # Truncate the packet we just got out of the buffer

            except asyncio.CancelledError:
                break


    async def queue_packet(self, packet: bytes):
        await self.outqueue.put( struct.pack("<H", len(packet)) + packet )


    async def process_packet(self, packet: bytes):
        offset: int = 0
        match pType := getPacketType(packet):
            case PacketType.HE: # Hello packet
                self.addr = struct.unpack_from("<36s", packet, offset=1)[0]
                await self.queue_packet( struct.pack("<Bx", 1) )
            case PacketType.DA: # Data
                daddr: bytes
                port: int
                self.addr, daddr, port = struct.unpack_from("<36s 36s H", packet, offset=offset+1) # Offset is 0 above, but we already read 1 byte when getting the type
                if daddr.startswith(b"BROADCAST"):
                    await self.Manager.broadcast(self, port, packet)
                else:
                    await self.Manager.direct(self, daddr, port, packet)
            case PacketType.PO | PacketType.PC: # Port stuff
                port: int = struct.unpack_from("<H", packet, offset=1)[0]
                if pType == PacketType.PO:
                    self.ports.add(port)
                else:
                    self.ports.remove(port)
    
    async def write_loop(self):
        while True:
            try:
                try:
                    data_to_send: bytes = await asyncio.wait_for(self.outqueue.get(), timeout=60.0)
                    self.writer.write(data_to_send)
                except TimeoutError:
                    await self.queue_packet( struct.pack("<Bx", 1) ) # KeepAlive
                except asyncio.CancelledError:
                    break
                except:
                    self.logger.exception("in writing loop!")
                await self.writer.drain()
            except asyncio.CancelledError:
                self.logger.warning("Write task cancelled!")
                self.writer.close()
                await self.writer.wait_closed()
                break
            except ConnectionResetError:
                self.logger.warning("Connectionm got reset!")
                await self.close()
                break

class ArgType(IntEnum):
    STRING = 1
    NUMBER = 2
    BOOLEAN = 3
    NIL = 4


class ClientManager:
    def __init__(self):
        self.clients: set[Client] = set()
        self.clients_closed: set[Client] = set()
        self.logger = logging.getLogger("ClientManager")
        self.logger.info("We're good to go!")

    async def cleanup_clients(self):
        while True:
            for client in copy.copy(self.clients):
                try:
                    self.logger.debug(f"checking on {client}")
                    if client.closed:
                        self.logger.debug(f"Client is closed!! {client}")
                        self.clients.remove(client)
                        del client
                except:
                    self.logger.exception(f"trying to remove {client}")
                
            await asyncio.sleep(10)
    
    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        c = Client(self, reader, writer)
        self.clients.add(c)
        await c.start()

    async def broadcast(self, sending_client: Client, port: int, dataline: bytes):
        for client in self.clients:
            if client is sending_client or client.addr == sending_client.addr: 
                continue
            if port in client.ports:
                self.logger.debug(f"{sending_client.addr} =>> {client.addr}")
                await client.outqueue.put( struct.pack("<H", len(dataline)) + dataline)
    async def direct(self, sending_client: Client, destination: bytes, port: int, dataline: bytes):
        for client in self.clients:
            if client.addr == destination and port in client.ports:
                self.logger.debug(f"{sending_client.addr} -> {destination}")
                await client.outqueue.put( struct.pack("<H", len(dataline)) + dataline)
                break # don't need to continue looping over clients
        


async def main():
    cm = ClientManager()
    task = asyncio.create_task(cm.cleanup_clients())
    server = await asyncio.start_server( cm.handle_client, '0.0.0.0', 4096)
    async with server:
        await server.serve_forever()
    task.cancel()

asyncio.run(main())
