# PC Companion — networking & reconnect

The PC companion (`nfcc_pc`) and phone talk over **your local Wi-Fi only**. Nothing leaves the LAN — no cloud relay, no account.

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
