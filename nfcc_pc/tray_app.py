"""System tray application for NFCC PC companion.

This is the only thing keeping the PC companion process alive when the
user closes the browser / terminal. The tray is not optional — quitting
the tray is what ends the service.
"""

from __future__ import annotations

import logging
import socket
import threading
from typing import Callable, Optional

import pystray
from PIL import Image, ImageDraw

logger = logging.getLogger("nfcc")


def _local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def create_icon_image(connected: bool = False) -> Image.Image:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    color = (0, 176, 255) if connected else (156, 163, 175)
    center = size // 2
    for r in [12, 20, 28]:
        bbox = (center - r, center - r, center + r, center + r)
        draw.arc(bbox, -45, 45, fill=color, width=3)
    draw.ellipse((center - 4, center - 4, center + 4, center + 4), fill=color)
    return img


class TrayApp:
    def __init__(
        self,
        *,
        config: Optional[dict] = None,
        on_show_dashboard: Optional[Callable[[], None]] = None,
        on_copy_pairing: Optional[Callable[[], str]] = None,
        on_quit: Optional[Callable[[], None]] = None,
    ):
        self.config = config or {}
        self.on_show_dashboard = on_show_dashboard
        self.on_copy_pairing = on_copy_pairing
        self.on_quit = on_quit
        self._icon: Optional[pystray.Icon] = None
        self._status = "Starting…"
        self._connected = False

    # ── Lifecycle ────────────────────────────────────────────────────

    def start(self) -> None:
        port = self.config.get("port", 9876)
        endpoint = f"{_local_ip()}:{port}"

        menu = pystray.Menu(
            pystray.MenuItem("NFCC — NFC Control", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem(lambda _: self._status, None, enabled=False),
            pystray.MenuItem(lambda _: f"Endpoint  {endpoint}", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Open Dashboard…", self._on_show_dashboard),
            pystray.MenuItem("Copy Pairing JSON", self._on_copy_pairing),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Quit NFCC", self._on_quit),
        )
        self._icon = pystray.Icon(
            "NFCC",
            icon=create_icon_image(False),
            title=f"NFCC — {self._status}",
            menu=menu,
        )
        self._icon.run()

    def stop(self) -> None:
        if self._icon:
            self._icon.stop()

    # ── External hooks (called from NfccApp) ─────────────────────────

    def update_status(self, status: str, connected: bool = False) -> None:
        self._status = status
        self._connected = connected
        if self._icon:
            self._icon.icon = create_icon_image(connected)
            port = self.config.get("port", 9876)
            self._icon.title = f"NFCC — {status}  ({_local_ip()}:{port})"
            self._icon.update_menu()

    # ── Menu handlers ────────────────────────────────────────────────

    def _on_show_dashboard(self, icon, item) -> None:
        if self.on_show_dashboard:
            threading.Thread(target=self.on_show_dashboard, daemon=True).start()

    def _on_copy_pairing(self, icon, item) -> None:
        if not self.on_copy_pairing:
            return
        payload = self.on_copy_pairing()
        try:
            import pyperclip  # optional
            pyperclip.copy(payload)
            logger.info("Pairing JSON copied to clipboard")
        except Exception:
            # Fallback: stash it in %TEMP% so the user can grab it.
            import os, tempfile
            path = os.path.join(tempfile.gettempdir(), "nfcc-pairing.json")
            with open(path, "w") as f:
                f.write(payload)
            logger.info(f"Pairing JSON written to {path} (install `pyperclip` for clipboard support)")

    def _on_quit(self, icon, item) -> None:
        if self.on_quit:
            self.on_quit()
        self.stop()
