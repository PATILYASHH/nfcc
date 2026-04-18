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
    # If the tray service isn't up, bring it up first. The dashboard
    # HTTP server lives inside the tray process — it keeps running
    # forever, independent of whether any browser tab is open — so a
    # single `NFCC-PC serve` is enough to answer every future
    # `NFCC-PC dashboard` / `NFCC-PC` launch.
    if not _is_service_running():
        print("NFCC-PC: no service detected on :8877, starting one in the background…")
        # Spawn serve as a detached background process so the terminal
        # returns immediately and the tray service survives this shell.
        _spawn_serve_detached()
        # Give it a moment to bind the port so the browser lands on a
        # working page rather than a connection-refused error.
        _wait_for_service(timeout_s=8)
    webbrowser.open(url)
    print(f"Opened {url}")
    return 0


def _spawn_serve_detached() -> None:
    """Launch `NFCC-PC serve` as a **fully detached** background process.

    The child must survive:
      * the cmd window that ran `NFCC-PC`
      * the browser tab that was auto-opened
      * the parent Python interpreter exiting

    On Windows the only way to guarantee that is:
      1. Use pythonw.exe (or the frozen --windowed .exe) — no console
         at all, so there's no console handle to inherit.
      2. Clear every std stream via DEVNULL so even accidental handle
         inheritance can't tie it to the parent.
      3. Combine DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP |
         CREATE_BREAKAWAY_FROM_JOB — the last one is critical, because
         terminals (cmd.exe, Windows Terminal) place children in a Job
         Object that kills them all when the terminal closes unless
         BREAKAWAY_FROM_JOB is set.
      4. Set cwd to a stable absolute path so config lookups don't
         depend on where NFCC-PC was invoked from.
    """
    import os, shutil, subprocess
    script_dir = os.path.dirname(os.path.abspath(__file__))

    if getattr(sys, "frozen", False):
        args = [sys.executable, "serve"]
    else:
        pythonw = shutil.which("pythonw") or os.path.join(
            os.path.dirname(sys.executable), "pythonw.exe"
        )
        main_py = os.path.abspath(__file__)
        args = [pythonw, main_py, "serve"]

    DETACHED_PROCESS = 0x00000008
    CREATE_NEW_PROCESS_GROUP = 0x00000200
    CREATE_BREAKAWAY_FROM_JOB = 0x01000000
    CREATE_NO_WINDOW = 0x08000000

    if sys.platform == "win32":
        creationflags = (
            DETACHED_PROCESS
            | CREATE_NEW_PROCESS_GROUP
            | CREATE_BREAKAWAY_FROM_JOB
            | CREATE_NO_WINDOW
        )
        subprocess.Popen(
            args,
            cwd=script_dir,
            close_fds=True,
            creationflags=creationflags,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    else:
        subprocess.Popen(
            args,
            cwd=script_dir,
            close_fds=True,
            start_new_session=True,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def _wait_for_service(timeout_s: float = 8.0) -> bool:
    import time
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        if _is_service_running():
            return True
        time.sleep(0.25)
    return False


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


def cmd_health(args) -> int:
    """One-glance diagnostic: is everything that needs to be up actually up?"""
    import urllib.request
    checks = []

    # 1. Dashboard HTTP
    try:
        with urllib.request.urlopen("http://localhost:8877/api/status", timeout=1) as r:
            data = json.loads(r.read())
        checks.append(("service", True,
                       f"answering on :8877 — {data.get('devices', 0)} device(s), "
                       f"{data.get('action_count', 0)} action(s) since start"))
    except Exception as e:
        checks.append(("service", False, f"NO ANSWER on :8877 ({e})"))

    # 2. WebSocket bound
    import socket as _s
    try:
        t = _s.socket()
        t.settimeout(0.5)
        config = load_config()
        t.connect(("127.0.0.1", config["port"]))
        t.close()
        checks.append(("websocket", True, f"listening on :{config['port']}"))
    except Exception as e:
        checks.append(("websocket", False, f"NOT listening ({e})"))

    # 3. Autostart
    try:
        import autostart
        ok = autostart.is_autostart_enabled()
        checks.append(("autostart", ok,
                       "registered in HKCU\\…\\Run" if ok else "NOT registered"))
    except Exception as e:
        checks.append(("autostart", False, str(e)))

    # Print a neat table
    all_ok = all(ok for _, ok, _ in checks)
    for name, ok, detail in checks:
        mark = "OK  " if ok else "FAIL"
        print(f"  [{mark}] {name:10s} {detail}")
    print()
    if all_ok:
        print("  All systems go. Closing browsers does NOT affect the service.")
    else:
        print("  Start the service with:  NFCC-PC   (or NFCC-PC serve for headless)")
    return 0 if all_ok else 1


def cmd_autostart(args) -> int:
    """Enable / disable / check Windows auto-start on login."""
    try:
        import autostart
    except ImportError:
        print("error: autostart is Windows-only", file=sys.stderr)
        return 1
    if args.action == "enable":
        autostart.enable_autostart()
        print(f"autostart enabled — runs on login from: {autostart.get_exe_path()}")
        return 0
    if args.action == "disable":
        autostart.disable_autostart()
        print("autostart disabled")
        return 0
    # status (default)
    enabled = autostart.is_autostart_enabled()
    print(f"enabled:    {enabled}")
    print(f"executable: {autostart.get_exe_path()}")
    print(f"registry:   HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\NFCC")
    return 0


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

    pas = sub.add_parser("autostart", help="manage Windows auto-start on login")
    pas.add_argument("action", nargs="?", default="status",
                     choices=["enable", "disable", "status"])
    pas.set_defaults(func=cmd_autostart)

    sub.add_parser("health", help="is the service answering? is autostart on?").set_defaults(func=cmd_health)

    return p


def _is_service_running() -> bool:
    """True if another `NFCC-PC serve` is already answering on :8877."""
    import urllib.request
    try:
        urllib.request.urlopen("http://localhost:8877/api/status", timeout=1)
        return True
    except Exception:
        return False


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    # Bare `NFCC-PC` in a terminal = open the dashboard (the webpage IS
    # the GUI). cmd_dashboard handles "start the service if it isn't up
    # yet" transparently, so users can just type the command and always
    # get a working page — regardless of whether autostart put a tray
    # service in place, and regardless of whether the browser is open.
    if args.cmd is None:
        sys.exit(cmd_dashboard(argparse.Namespace()))
        return

    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
