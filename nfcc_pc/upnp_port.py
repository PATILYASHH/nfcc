"""Optional UPnP / IGD port-forwarding helper.

The user's router has to support UPnP (most consumer routers do; many
ISPs disable it by default for security). This module is entirely
opt-in — the companion works fine on the LAN without it. Forwarding
is only useful if the user wants the phone to reach the PC from a
different network / from outside the home.

Uses `miniupnpc`, LGPL. Safe to ship alongside MIT code.
"""

from __future__ import annotations

import logging
import socket
from typing import Optional

logger = logging.getLogger("nfcc")


class UpnpError(Exception):
    pass


def _local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def _client():
    try:
        import miniupnpc  # type: ignore
    except ImportError as e:
        raise UpnpError(
            "miniupnpc is not installed. Run:  pip install miniupnpc"
        ) from e
    u = miniupnpc.UPnP()
    u.discoverdelay = 200
    try:
        n = u.discover()
    except Exception as e:
        raise UpnpError(f"UPnP discovery failed: {e}") from e
    if n < 1:
        raise UpnpError(
            "No UPnP-capable router found on the LAN. "
            "Enable UPnP in your router admin and try again, or "
            "configure port-forwarding manually."
        )
    try:
        u.selectigd()
    except Exception as e:
        raise UpnpError(f"No Internet Gateway selectable: {e}") from e
    return u


def forward(port: int, description: str = "NFCC PC Companion") -> dict:
    """Open TCP <port> on the router for this PC's LAN IP.

    Returns a dict with `external_ip`, `external_port`, `internal_ip`.
    Raises UpnpError with a human-readable reason on any failure.
    """
    u = _client()
    internal = _local_ip()
    external_ip = u.externalipaddress()
    try:
        ok = u.addportmapping(
            port,            # external port
            "TCP",           # protocol
            internal,        # internal (LAN) host
            port,            # internal port
            description,     # description shown in router UI
            "",              # remote host ("" = any)
        )
    except Exception as e:
        raise UpnpError(f"addportmapping error: {e}") from e
    if not ok:
        raise UpnpError(
            f"Router refused to map {port}. It may already be mapped "
            f"by another app, or UPnP writes are disabled."
        )
    logger.info(f"UPnP: mapped {external_ip}:{port} -> {internal}:{port}")
    return {
        "external_ip": external_ip,
        "external_port": port,
        "internal_ip": internal,
        "internal_port": port,
        "description": description,
    }


def unforward(port: int) -> bool:
    """Remove the TCP port mapping. Returns True on success."""
    try:
        u = _client()
        ok = u.deleteportmapping(port, "TCP")
        logger.info(f"UPnP: removed mapping for {port}: ok={ok}")
        return bool(ok)
    except UpnpError:
        return False
    except Exception as e:
        logger.warning(f"UPnP: unforward error: {e}")
        return False


def external_ip() -> Optional[str]:
    """Return the router's WAN IP, or None if UPnP is not available."""
    try:
        return _client().externalipaddress()
    except UpnpError:
        return None
    except Exception:
        return None
