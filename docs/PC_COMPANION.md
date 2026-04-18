# PC Companion — networking, reconnect, CLI

The PC companion (`nfcc_pc`) and phone talk over **your local Wi-Fi only**. Nothing leaves the LAN — no cloud relay, no account.

## Running modes

The companion is three things in one process:

1. **Tray service** — the background WebSocket + UDP discovery. This is what the phone actually talks to. **Only the tray icon keeps the process alive.** Closing the browser, the dashboard, or the terminal you launched from does **not** stop it.
2. **Local dashboard** at `http://localhost:8877` — a pure frontend. Open it from the tray when you want to see status, pairing QR, and the action log. Close the tab any time — the service keeps running.
3. **CLI** — a small `nfcc` command for terminals and scripts.

### Start headless (recommended)

Windows — double-click `start-background.bat` (ships in `nfcc_pc/`). It calls `pythonw.exe` which has no console window, so there's nothing to accidentally close.

Or the built `NFCC-Companion.exe` (from the release page) is compiled with PyInstaller `--windowed` — same effect.

### Start from a terminal (development)

```
python main.py            # = python main.py serve
python main.py serve      # foreground, Ctrl+C to stop
```

The tray icon is still what keeps it alive in this mode too; the terminal is only there for logs.

### The `NFCC-PC` terminal command

Add `nfcc_pc/` to your `PATH` and you can run from any directory in any terminal:

```
NFCC-PC                                # same as `NFCC-PC serve`
NFCC-PC serve [--open-browser]         # start the tray service
NFCC-PC status                         # print config + IP + port
NFCC-PC pair                           # print pairing JSON for copy/paste
NFCC-PC dashboard                      # open the dashboard in the browser
NFCC-PC reconnect                      # tell the running service to restart its network services
NFCC-PC forward [--port N]             # open the port on your router via UPnP
NFCC-PC unforward [--port N]           # remove the UPnP port mapping
NFCC-PC action lockPc                  # execute a PC action locally, no network
NFCC-PC action launchApp --params '{"name":"notepad"}'
```

- **`NFCC-PC reconnect`** hits `POST http://localhost:8877/api/reconnect` on the already-running tray service. It stops and restarts the WebSocket server + UDP discovery in-place, which rebinds ports (picking up the port-fallback range) and re-announces to phones. Paired phones auto-re-authenticate within a few seconds.
- **`NFCC-PC forward`** uses UPnP (IGD v1/v2) to ask the router to open the current port. Works on routers with UPnP enabled — most consumer routers, many ISPs have disabled it. See the next section.
- **`NFCC-PC action`** runs through the same `execute_action()` path the WebSocket uses — perfect for Task Scheduler jobs and shell scripts without involving the phone at all.

Inside the tray menu, the same three actions are now exposed as **Reconnect (restart services)** and **Forward Port via UPnP** alongside **Open Dashboard…** and **Copy Pairing JSON**.

## UPnP port forwarding

By default the companion is LAN-only. If you want phones on *other* networks (cellular, other Wi-Fi) to reach your PC, you need an inbound port open on your router. `NFCC-PC forward` does this automatically via UPnP:

```
> NFCC-PC forward
{
  "external_ip":   "203.0.113.42",
  "external_port": 9876,
  "internal_ip":   "192.168.0.119",
  "internal_port": 9876,
  "description":   "NFCC PC Companion"
}
```

After that, pair the phone once at `ws://<external_ip>:9876` and it will reach your PC from anywhere.

**Caveats.**
- UPnP must be enabled in your router admin. Many routers ship with it off for security.
- Exposing a service to the public internet is a security trade-off. The PC companion requires a pairing token, so random scanners can't issue commands — but the **attack surface is larger** than LAN-only mode.
- Double-NAT / carrier-grade NAT (common on cellular and some fibre ISPs) means UPnP on the local router does nothing. In that case use **Tailscale** or **WireGuard** (see below) — both are free and libre and much safer than opening router ports.

To take the mapping back down:
```
> NFCC-PC unforward
removed=True
```

Mappings persist until you unforward, reboot the router, or the router's lease expires (~24 h on most).



## The two ports

| Port       | Protocol | Purpose                              |
| ---------- | -------- | ------------------------------------ |
| **9876**   | TCP (WebSocket) | Phone → PC command channel |
| **9877**   | UDP      | Phone broadcasts `NFCC_DISCOVER`; PC replies with its IP+port+token |

Both bind to `0.0.0.0`, so the PC is reachable on every network interface it has (Ethernet + Wi-Fi simultaneously).

## Port fallback (v1.0+)

If port **9876** is occupied (e.g. another NFCC instance, a dev server, a debugger), the PC companion walks forward `9876 → 9886` and binds the first free port. The chosen port is:

1. written back to `~/.nfcc/config.json` so subsequent starts prefer it, and
2. broadcast via UDP discovery so the phone re-pairs automatically on its next rediscovery cycle.

## Reconnect across network changes

The phone's `PcConnectionService` keeps a persistent record of the paired PC (`id`, `ip`, `port`, `pairing_token`). When the connection drops:

1. **Attempts 1 – 2** — retry the cached `ip:port` (fast: 1 s, 2 s backoff).
2. **Every 3rd attempt** — broadcast a UDP `NFCC_DISCOVER`. If a PC responds with the **same pairing token**, its current IP/port replaces the cached one.
3. **Steady state** — exponential backoff caps at 60 s between attempts, retrying forever until the user disconnects.

This covers:
- PC restarted → DHCP gave it a new IP.
- Phone hopped WiFi networks.
- Router reset.
- PC port changed due to port-fallback above.

There's also a `refreshConnection()` entry point the UI calls from a "Reconnect now" button, bypassing the backoff.

## Cross-subnet / remote access (advanced)

By default NFCC is LAN-only. If you want to tap a tag at home and have it fire actions on your PC at the office, you have two free and libre options:

**Option A — Port forward on your home router**
- In your router's admin UI, forward TCP 9876 → your PC's LAN IP.
- (Optional) Forward UDP 9877 too so rediscovery works.
- Re-pair the phone once with the router's **public IP** on the office Wi-Fi.

**Option B — Self-hosted VPN (recommended)**
Run [Tailscale](https://tailscale.com/) or [WireGuard](https://www.wireguard.com/) on both devices. They get stable 100.x.x.x IPs that survive network changes, and all traffic is end-to-end encrypted. No router surgery needed. Pair with the Tailscale IP of the PC.

We do **not** embed a hole-punching or relay service inside NFCC — that would break the "no cloud" guarantee.

## Firewall on Windows

On the first run, Windows will pop a Defender prompt asking whether to allow `NFCC-Companion.exe` on Private networks. **Allow it**. If you missed the prompt:

```
Control Panel → System and Security → Windows Defender Firewall →
  Allow an app through firewall → NFCC-Companion.exe (check "Private")
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Phone says "PC offline" on the same WiFi | Check the tray icon is green. Check Defender allowed the app on Private networks. |
| Connection drops every few minutes | Your AP probably enforces AP Isolation / Guest mode, which blocks client-to-client traffic. Turn it off, or move to a trusted SSID. |
| Can't find PC in "Auto-discover" | UDP broadcast is sometimes blocked on Windows Hotspot / guest SSIDs. Use the QR pair flow instead. |
| Pair worked once, never reconnects | v1.0 rediscovery handles this — pull-to-refresh on the Settings → Pair PC screen, or tap "Reconnect now". |
| `NFCC-Companion.exe` won't start | Another process is on 9876–9886. Close it, or edit `%USERPROFILE%\.nfcc\config.json` and set `"port": 9890`. |
