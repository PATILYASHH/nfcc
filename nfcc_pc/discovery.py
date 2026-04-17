"""UDP broadcast responder for phone discovery on LAN."""

import asyncio
import json
import logging
import socket

logger = logging.getLogger("nfcc")

DISCOVERY_PORT = 9877
MAGIC = b"NFCC_DISCOVER"


class DiscoveryResponder:
    """Listens for UDP broadcast discovery packets from the phone app
    and responds with this PC's connection info."""

    def __init__(self, config: dict):
        self.config = config
        self._running = False
        self._transport = None

    async def start(self):
        self._running = True
        loop = asyncio.get_event_loop()

        # Create UDP socket
        self._transport, _ = await loop.create_datagram_endpoint(
            lambda: _DiscoveryProtocol(self.config),
            local_addr=("0.0.0.0", DISCOVERY_PORT),
            family=socket.AF_INET,
            allow_broadcast=True,
        )
        logger.info(f"Discovery responder listening on UDP port {DISCOVERY_PORT}")

    def stop(self):
        self._running = False
        if self._transport:
            self._transport.close()
            self._transport = None


class _DiscoveryProtocol(asyncio.DatagramProtocol):
    def __init__(self, config: dict):
        self.config = config

    def datagram_received(self, data: bytes, addr: tuple):
        if data.startswith(MAGIC):
            response = json.dumps({
                "id": self.config["id"],
                "name": socket.gethostname(),
                "ip": _get_local_ip(),
                "port": self.config["port"],
                "token": self.config["pairing_token"],
            }).encode()
            self.transport.sendto(response, addr)
            logger.info(f"Discovery: responded to {addr[0]}")

    def connection_made(self, transport):
        self.transport = transport


def _get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()
