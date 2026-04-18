"""NFCC PC Companion.

Runs as a tray-resident background service that exposes a WebSocket to the
phone app plus a local HTTP dashboard. The dashboard is *optional* — it's
just a frontend; opening or closing the browser tab never affects the tray
service or WebSocket.

Also exposes a tiny command-line so terminals can use it like a CLI:

  nfcc                     # same as `nfcc serve` — start tray + WebSocket
  nfcc serve               # start tray + WebSocket (blocking)
  nfcc pair                # print pairing JSON and the dashboard URL
  nfcc status              # print current config + known paired port / IP
  nfcc action <name> [--params '{"foo":"bar"}']
                           # execute one PC action locally (no network)
  nfcc dashboard           # open the dashboard in the default browser
                           # (requires a running `nfcc serve` in another
                           # process — the dashboard lives inside serve)

Run headless on Windows by launching with `pythonw.exe main.py` or the
built `NFCC-Companion.exe` (PyInstaller `--windowed`), both of which
detach from any console.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import socket
import sys
import threading
import webbrowser

from config import load_config, save_config
from logger import setup_logging

logger = setup_logging()


# ══════════════════════════════════════════════════════════════════════
#  `nfcc serve` — the normal tray-resident background service
# ══════════════════════════════════════════════════════════════════════

class NfccApp:
    def __init__(self, *, open_browser: bool = False):
        self.config = load_config()
        self.open_browser = open_browser
        self.tray = None
        self.server = None
        self.discovery = None
        self._loop: asyncio.AbstractEventLoop | None = None
        self._dashboard = None

    def run(self) -> None:
        # Local imports so the `nfcc action` / `nfcc status` paths don't
        # drag in pystray / websockets when running one-shot commands.
        from websocket_server import NfccWebSocketServer
        from discovery import DiscoveryResponder
        from tray_app import TrayApp
        from web_dashboard import start_dashboard, open_dashboard, get_state

        logger.info("NFCC PC Companion starting…")
        logger.info(f"  port={self.config['port']}  id={self.config['id'][:8]}…")

        # Dashboard HTTP server is always up (it's cheap) but the browser
        # is only opened if the user explicitly asked for it. Closing the
        # browser tab cannot kill the process because it lives entirely
        # in this Python process — not in the browser.
        self._dashboard = start_dashboard(self.config)
        logger.info("Dashboard available at http://localhost:8877  (open from tray)")

        self._loop = asyncio.new_event_loop()
        threading.Thread(target=self._run_async_loop, daemon=True).start()

        if self.open_browser:
            open_dashboard()

        # Tray keeps the process alive until the user picks Quit.
        self._WsServer = NfccWebSocketServer  # used later
        self._get_state = get_state
        self.tray = TrayApp(
            config=self.config,
            on_show_dashboard=lambda: open_dashboard(),
            on_copy_pairing=self._copy_pairing,
            on_quit=self._quit,
        )
        self.tray.start()

    def _run_async_loop(self) -> None:
        from websocket_server import NfccWebSocketServer
        from discovery import DiscoveryResponder

        asyncio.set_event_loop(self._loop)

        async def start():
            self.server = NfccWebSocketServer(
                self.config,
                on_status_change=self._on_status_change,
                on_action_executed=self._on_action_executed,
            )
            await self.server.start()
            self.discovery = DiscoveryResponder(self.config)
            await self.discovery.start()
            self._on_status_change("Waiting for connection…")

        self._loop.run_until_complete(start())
        self._loop.run_forever()

    def _on_status_change(self, status: str) -> None:
        connected = "Connected" in status or "device" in status
        state = self._get_state()
        state.status = status
        if self.server:
            state.connected_devices = list(range(self.server.connected_count))
        if self.tray:
            self.tray.update_status(status, connected)

    def _on_action_executed(self, action: str, success: bool, detail: str) -> None:
        state = self._get_state()
        state.add_log(action, success, detail)

    def _copy_pairing(self) -> str:
        return json.dumps(_pairing_payload(self.config))

    def _quit(self) -> None:
        logger.info("Shutting down…")
        if self._loop and self._loop.is_running():
            future = asyncio.run_coroutine_threadsafe(self._stop(), self._loop)
            try:
                future.result(timeout=5)
            except Exception:
                logger.warning("Shutdown timed out, forcing exit")
        sys.exit(0)

    async def _stop(self) -> None:
        if self.server:
            await self.server.stop()
        if self.discovery:
            self.discovery.stop()


# ══════════════════════════════════════════════════════════════════════
#  Shared helpers
# ══════════════════════════════════════════════════════════════════════

def _local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def _pairing_payload(config: dict) -> dict:
    return {
        "id": config["id"],
        "name": socket.gethostname(),
        "ip": _local_ip(),
        "port": config["port"],
        "token": config["pairing_token"],
    }


# ══════════════════════════════════════════════════════════════════════
#  One-shot CLI commands — useful from a terminal or a shell script
# ══════════════════════════════════════════════════════════════════════

def cmd_pair(args) -> int:
    config = load_config()
    payload = _pairing_payload(config)
    print(json.dumps(payload, indent=2))
    print()
    print(f"Dashboard: http://localhost:8877  (when `nfcc serve` is running)")
    print(f"WebSocket: ws://{payload['ip']}:{payload['port']}")
    return 0


def cmd_status(args) -> int:
    config = load_config()
    print(f"id:           {config['id']}")
    print(f"port:         {config['port']}  (fallback range 9876..9886)")
    print(f"pairing_token:{config['pairing_token']}")
    print(f"hostname:     {socket.gethostname()}")
    print(f"local_ip:     {_local_ip()}")
    print()
    print("To launch the background service:  nfcc serve")
    print("To open the dashboard:             nfcc dashboard")
    return 0


def cmd_action(args) -> int:
    from action_executor import execute_action

    params = {}
    if args.params:
        try:
            params = json.loads(args.params)
        except json.JSONDecodeError as e:
            print(f"error: --params is not valid JSON: {e}", file=sys.stderr)
            return 2
    if not isinstance(params, dict):
        print("error: --params must decode to a JSON object", file=sys.stderr)
        return 2
    success, message, data = execute_action(args.name, params)
    print(json.dumps({"success": success, "message": message, "data": data}, indent=2))
    return 0 if success else 1


def cmd_dashboard(args) -> int:
    url = "http://localhost:8877"
    webbrowser.open(url)
    print(f"Opened {url}  (the dashboard only answers when `nfcc serve` is running)")
    return 0


def cmd_serve(args) -> int:
    NfccApp(open_browser=args.open_browser).run()
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="nfcc",
        description="NFCC PC Companion — tray-resident WebSocket + local "
                    "dashboard + one-shot action CLI.",
    )
    sub = p.add_subparsers(dest="cmd")

    ps = sub.add_parser("serve", help="run the tray service (default)")
    ps.add_argument("--open-browser", action="store_true",
                    help="open the dashboard in the browser at startup")
    ps.set_defaults(func=cmd_serve)

    sub.add_parser("status", help="print config + network info").set_defaults(func=cmd_status)
    sub.add_parser("pair", help="print pairing JSON").set_defaults(func=cmd_pair)
    sub.add_parser("dashboard", help="open the dashboard in the browser").set_defaults(func=cmd_dashboard)

    pa = sub.add_parser("action", help="execute one PC action locally (no network)")
    pa.add_argument("name", help="action name, e.g. lockPc, launchApp, volumeUp")
    pa.add_argument("--params", help="JSON object of parameters, e.g. '{\"name\":\"notepad\"}'")
    pa.set_defaults(func=cmd_action)

    return p


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    # Default to `serve` so double-clicking / pythonw launches the tray.
    if args.cmd is None:
        cmd_serve(argparse.Namespace(open_browser=False))
        return

    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
