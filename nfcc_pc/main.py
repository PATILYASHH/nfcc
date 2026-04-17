"""NFCC PC Companion - Main entry point.

System tray app + web dashboard.
Receives commands from NFCC mobile app via WebSocket.
"""

import asyncio
import logging
import threading
import sys

from config import load_config
from logger import setup_logging
from websocket_server import NfccWebSocketServer
from discovery import DiscoveryResponder
from tray_app import TrayApp
from web_dashboard import start_dashboard, open_dashboard, get_state

logger = setup_logging()


class NfccApp:
    def __init__(self):
        self.config = load_config()
        self.tray: TrayApp = None
        self.server: NfccWebSocketServer = None
        self.discovery: DiscoveryResponder = None
        self._loop: asyncio.AbstractEventLoop = None
        self._dashboard = None

    def run(self):
        logger.info("NFCC PC Companion starting...")
        logger.info(f"Config: port={self.config['port']}, id={self.config['id'][:8]}...")

        # Start web dashboard
        self._dashboard = start_dashboard(self.config)
        logger.info("Dashboard running at http://localhost:8877")

        # Start asyncio event loop in background thread
        self._loop = asyncio.new_event_loop()
        async_thread = threading.Thread(target=self._run_async_loop, daemon=True)
        async_thread.start()

        # Open dashboard in browser
        open_dashboard()

        # Start tray app (blocks main thread)
        self.tray = TrayApp(
            on_show_dashboard=lambda: open_dashboard(),
            on_quit=self._quit,
        )
        self.tray.start()

    def _run_async_loop(self):
        asyncio.set_event_loop(self._loop)
        self._loop.run_until_complete(self._start_services())
        self._loop.run_forever()

    async def _start_services(self):
        self.server = NfccWebSocketServer(
            self.config,
            on_status_change=self._on_status_change,
            on_action_executed=self._on_action_executed,
        )
        await self.server.start()

        self.discovery = DiscoveryResponder(self.config)
        await self.discovery.start()

        self._on_status_change("Waiting for connection...")

    def _on_status_change(self, status: str):
        connected = "Connected" in status
        state = get_state()
        state.status = status
        if self.server:
            state.connected_devices = list(range(self.server.connected_count))
        if self.tray:
            self.tray.update_status(status, connected)

    def _on_action_executed(self, action: str, success: bool, detail: str):
        state = get_state()
        state.add_log(action, success, detail)

    def _quit(self):
        logger.info("Shutting down...")
        if self._loop and self._loop.is_running():
            future = asyncio.run_coroutine_threadsafe(self._stop_services(), self._loop)
            try:
                future.result(timeout=5)
            except Exception:
                logger.warning("Shutdown timed out, forcing exit")
        sys.exit(0)

    async def _stop_services(self):
        if self.server:
            await self.server.stop()
        if self.discovery:
            self.discovery.stop()


def main():
    app = NfccApp()
    app.run()


if __name__ == "__main__":
    main()
