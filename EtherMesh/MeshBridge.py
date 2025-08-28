import asyncio
import logging
import json

logging.basicConfig(level=logging.DEBUG)


class Client:
    def __init__(self, Manager: 'ClientManager', reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        self.Manager = Manager
        client_addr = writer.get_extra_info('peername')
        self.logger = Manager.logger.getChild(f"{client_addr[0]}#{client_addr[1]}")
        self.logger.info("New client!")
        self.reader = reader
        self.writer = writer
        self.outqueue = asyncio.Queue()
        self.tasks: set[asyncio.Task] = set()
        self.addr = "UNKNOWN"
        self.ports: set[int] = set()

    
    async def start(self):
        self.tasks.add(asyncio.create_task(self.read_loop()))
        self.tasks.add(asyncio.create_task(self.write_loop()))

    async def close(self):
        for task in self.tasks:
            task.cancel()
            await task
        await self.Manager.close_client(self)

    async def read_loop(self):
        while True:
            data = (await self.reader.readline()).decode("utf-8")
            if len(data) == 0:
                self.logger.info("Lost client!")
                await self.close()
            decoded = json.loads(data)
            print(decoded)
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
                    data_to_send = await asyncio.wait_for(self.outqueue.get(), timeout=60.0)
                    self.logger.critical(data_to_send)
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
        self.logger = logging.getLogger("ClientManager")
        self.logger.info("We're good to go!")
    
    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        c = Client(self, reader, writer)
        self.clients.add(c)
        await c.start()

    async def close_client(self, client: Client):
        self.clients.remove(client)
        del client

    async def broadcast(self, sending_client: Client, port: int, data: str):
        for client in self.clients:
            if client is sending_client: 
                continue
            await client.outqueue.put(dict(source=sending_client.addr, port=port, data=data) )
    async def direct(self, sending_client: Client, destination: str, port: int, data: str):
        for client in self.clients:
            if client.addr == destination:
                await client.outqueue.put(dict(source=sending_client.addr, port=port, data=data) )
        


async def main():
    cm = ClientManager()
    server = await asyncio.start_server( cm.handle_client, '0.0.0.0', 4096)
    async with server:
        await server.serve_forever()

asyncio.run(main())
