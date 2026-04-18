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
        self._dashboard = start_dashboard(
            self.config,
            on_reconnect=self._reconnect,
            on_forward=self._forward_port,
        )
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
            on_reconnect=self._reconnect,
            on_forward=self._forward_port,
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

    def _reconnect(self) -> None:
        """Restart WebSocket + discovery in-place. Picks up new IP, frees
        stuck connections, triggers phones to re-auth via the fresh
        discovery broadcast."""
        if not (self._loop and self._loop.is_running()):
            logger.warning("reconnect: async loop not running")
            return
        logger.info("reconnect: restarting network services…")

        async def _do_restart():
            if self.server:
                try:
                    await self.server.stop()
                except Exception as e:
                    logger.warning(f"reconnect: stop ws: {e}")
            if self.discovery:
                try:
                    self.discovery.stop()
                except Exception as e:
                    logger.warning(f"reconnect: stop discovery: {e}")
            # Re-import to avoid carrying stale state.
            from websocket_server import NfccWebSocketServer
            from discovery import DiscoveryResponder
            self.server = NfccWebSocketServer(
                self.config,
                on_status_change=self._on_status_change,
                on_action_executed=self._on_action_executed,
            )
            await self.server.start()
            self.discovery = DiscoveryResponder(self.config)
            await self.discovery.start()
            self._on_status_change("Reconnected — waiting for devices…")

        asyncio.run_coroutine_threadsafe(_do_restart(), self._loop)

    def _forward_port(self) -> dict:
        """Open the configured port on the router via UPnP."""
        from upnp_port import forward, UpnpError
        try:
            result = forward(self.config["port"])
            self._on_status_change(
                f"UPnP: {result['external_ip']}:{result['external_port']} open"
            )
            return result
        except UpnpError as e:
            logger.warning(f"forward: {e}")
            raise

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
    print(f"Opened {url}  (the dashboard only answers when `NFCC-PC serve` is running)")
    return 0


def cmd_serve(args) -> int:
    NfccApp(open_browser=args.open_browser).run()
    return 0


def cmd_reconnect(args) -> int:
    """Tell a running serve instance to restart its network services."""
    import urllib.request
    import urllib.error
    try:
        req = urllib.request.Request(
            "http://localhost:8877/api/reconnect",
            method="POST",
            headers={"Content-Type": "application/json"},
            data=b"{}",
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read().decode())
        if body.get("ok"):
            print("Reconnect triggered. Phone should re-pair within a few seconds.")
            return 0
        print(f"error: {body.get('error', 'unknown')}", file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(
            "error: cannot reach localhost:8877 — is the tray service running?\n"
            "       start it with:  NFCC-PC serve",
            file=sys.stderr,
        )
        print(f"       ({e})", file=sys.stderr)
        return 1


def cmd_forward(args) -> int:
    """Open the WebSocket port on the router via UPnP."""
    config = load_config()
    port = args.port or config["port"]
    try:
        from upnp_port import forward, UpnpError
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    try:
        result = forward(port)
    except UpnpError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    print(
        f"\nPhones on any network can now reach  ws://{result['external_ip']}:{result['external_port']}"
        "\nRemember: opening ports to the public internet is a security trade-off."
        "\nUndo with:  NFCC-PC unforward"
    )
    return 0


def cmd_unforward(args) -> int:
    config = load_config()
    port = args.port or config["port"]
    try:
        from upnp_port import unforward
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    ok = unforward(port)
    print(f"removed={ok}")
    return 0 if ok else 1


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="NFCC-PC",
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
    sub.add_parser("reconnect", help="tell a running serve to restart network services").set_defaults(func=cmd_reconnect)

    pf = sub.add_parser("forward", help="open the port on the router via UPnP")
    pf.add_argument("--port", type=int, default=None,
                    help="override port to forward (defaults to config port)")
    pf.set_defaults(func=cmd_forward)

    pu = sub.add_parser("unforward", help="remove the UPnP port mapping")
    pu.add_argument("--port", type=int, default=None)
    pu.set_defaults(func=cmd_unforward)

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
