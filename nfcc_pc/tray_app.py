"""System tray application for NFCC PC companion."""

import logging
import threading
from typing import Optional

import pystray
from PIL import Image, ImageDraw

logger = logging.getLogger("nfcc")


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
    def __init__(self, on_show_dashboard=None, on_quit=None):
        self.on_show_dashboard = on_show_dashboard
        self.on_quit = on_quit
        self._icon: Optional[pystray.Icon] = None
        self._status = "Starting..."
        self._connected = False

    def start(self):
        menu = pystray.Menu(
            pystray.MenuItem("NFCC - NFC Control", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem(lambda _: self._status, None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Open Dashboard", self._on_show_dashboard),
            pystray.MenuItem("Quit", self._on_quit),
        )
        self._icon = pystray.Icon(
            "NFCC",
            icon=create_icon_image(False),
            title="NFCC - NFC Control",
            menu=menu,
        )
        self._icon.run()

    def stop(self):
        if self._icon:
            self._icon.stop()

    def update_status(self, status: str, connected: bool = False):
        self._status = status
        self._connected = connected
        if self._icon:
            self._icon.icon = create_icon_image(connected)
            self._icon.title = f"NFCC - {status}"
            self._icon.update_menu()

    def _on_show_dashboard(self, icon, item):
        if self.on_show_dashboard:
            threading.Thread(target=self.on_show_dashboard, daemon=True).start()

    def _on_quit(self, icon, item):
        if self.on_quit:
            self.on_quit()
        self.stop()
