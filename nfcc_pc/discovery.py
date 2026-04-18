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
            # Reply with the IP of the interface the packet arrived on,
            # not whatever random outbound-route IP _get_local_ip() picks.
            # Fixes the "phone on Wi-Fi, PC has Ethernet + Wi-Fi, PC
            # advertises the wrong subnet" bug where discovery worked
            # but the WebSocket URL was unreachable.
            reply_ip = _local_ip_for(addr[0])
            response = json.dumps({
                "id": self.config["id"],
                "name": socket.gethostname(),
                "ip": reply_ip,
                "port": self.config["port"],
                "token": self.config["pairing_token"],
            }).encode()
            self.transport.sendto(response, addr)
            logger.info(f"Discovery: responded to {addr[0]} with {reply_ip}:{self.config['port']}")

    def connection_made(self, transport):
        self.transport = transport


def _local_ip_for(remote_ip: str) -> str:
    """The local IPv4 address Python would use to reach `remote_ip`.

    Opens a DGRAM socket (never actually sends anything) and asks the OS
    which local address would win the routing decision. Returns the
    correct interface even on a multi-homed host (Ethernet + Wi-Fi).
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect((remote_ip, 1))
        return s.getsockname()[0]
    except Exception:
        return _get_local_ip()
    finally:
        s.close()


def _get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()
