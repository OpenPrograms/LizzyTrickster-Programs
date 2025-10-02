import asyncio
import logging
import json
import coloredlogs
import luadata
import random
import copy

#logging.basicConfig(level=logging.DEBUG)
log_format = "%(asctime)s %(name)s %(levelname)s %(message)s"
fstyles = coloredlogs.DEFAULT_FIELD_STYLES | {'levelname':dict(bold=True, color="cyan")}
coloredlogs.install(level=logging.DEBUG, fmt=log_format, field_styles = fstyles)

class Client:
    def __init__(self, Manager: 'ClientManager', reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        self.Manager = Manager
        self.client_addr = writer.get_extra_info('peername')
        #self.logger = Manager.logger.getChild(f"{self.client_addr[0]}#{self.client_addr[1]}")
        self.reader = reader
        self.writer = writer
        self.outqueue = asyncio.Queue()
        self.tasks: set[asyncio.Task] = set()
        self.addr = "UNKNOWN"
        self.ports: set[int] = set()
        self.closed = False
        self.logger.info("New client!")

    @property
    def logger(self) -> logging.Logger:
        addr = getattr(self, 'addr', "UNKNOWN")
        return logging.getLogger(f"Client.{self.addr}@{self.client_addr[0]}#{self.client_addr[1]}")
    
    async def start(self):
        self.tasks.add(asyncio.create_task(self.read_loop()))
        self.tasks.add(asyncio.create_task(self.write_loop()))

    async def close(self):
        self.logger.warning("CLOSING")
        try:
            for task in self.tasks:
                task.cancel()
                #self.logger.debug(f"Cancelled {task}")
        except:
            self.logger.exception("Failed to cancel tasks?")
        self.closed = True

    def __str__(self):
        return f"<Client {[self.client_addr, self.addr, self.closed]}>"

    async def read_loop(self):
        while True:
            data = (await self.reader.readline()).decode("utf-8")
            if len(data) == 0:
                self.logger.info("Lost client!")
                await self.close()
            decoded = json.loads(data)
            if self.addr == "UNKNOWN":
               self.logger.critical("WE DON'T KNOW ADDRESS <><><><><><><>")
            match decoded['type']:
                case "KA":
                    datastr = json.dumps(dict(type="KA"))
                    self.writer.write((datastr+"\n").encode("utf-8"))
                    await self.writer.drain()
                case "HELLO":
                    self.addr = decoded['s']
                    [self.ports.add(port) for port in decoded['op']]
                case "POPEN":
                    self.ports.add(decoded['port'])
                case "PCLOSE":
                    self.ports.remove(decoded['port'])
                case "DATA":
                    if self.addr == "UNKNOWN":
                        self.writer.write((json.dumps(dict(type="WHO?"))+"\n").encode("utf-8") )
                        await self.writer.drain()
                    # self.logger.warning(f"{repr(decoded['D'])}")
                    if decoded['d'] == "BROADCAST":
                        await self.Manager.broadcast(self, decoded['p'], decoded['D'])
                        #self.logger.info(f"Broadcasting to the rest: {decoded}")
                    else:
                        await self.Manager.direct(self, decoded['d'], decoded['p'], decoded['D'])
                        self.logger.info(f"Sending direct to {decoded['d']}")
    
    async def write_loop(self):
        while True:
            try:
                try:
                    data_to_send = await asyncio.wait_for(self.outqueue.get(), timeout=10.0)
                    #self.logger.critical(data_to_send)
                    datastr = json.dumps( dict(type="DATA", s=data_to_send['source'], p=data_to_send['port'], D=data_to_send['data']))
                except TimeoutError:
                    datastr = json.dumps(dict(type="KA"))
                except asyncio.CancelledError:
                    break
                except:
                    self.logger.exception("in writing loop!")
                self.writer.write((datastr+"\n").encode("utf-8"))
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

    #async def close_client(self, client: Client):
    #    self.clients.remove(client)
    #    del client

    async def broadcast(self, sending_client: Client, port: int, data: str):
        for client in self.clients:
            if client is sending_client or client.addr == sending_client.addr: 
                continue
            self.logger.debug(f"{sending_client.addr} =>> {client.addr}")
            await client.outqueue.put(dict(source=sending_client.addr, port=port, data=data) )
    async def direct(self, sending_client: Client, destination: str, port: int, data: str):
        for client in self.clients:
            if client.addr == destination:
                self.logger.debug(f"{sending_client.addr} -> {destination}")
                await client.outqueue.put(dict(source=sending_client.addr, port=port, data=data) )
        


async def main():
    cm = ClientManager()
    task = asyncio.create_task(cm.cleanup_clients())
    server = await asyncio.start_server( cm.handle_client, '0.0.0.0', 4096)
    async with server:
        await server.serve_forever()
    task.cancel()

asyncio.run(main())
