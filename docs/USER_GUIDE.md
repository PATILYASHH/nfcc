# NFCC — User guide

## Installing

### Phone (Android)
Grab the APK from [Releases](https://github.com/PATILYASHH/nfcc/releases/latest) and install. Allow:
- NFC
- Location (coarse — needed to read Wi-Fi SSID for conditions)
- Bluetooth (scan + connect)
- Notifications

### PC companion
- Windows: run `NFCC-Companion.exe`. It lives in the system tray.
- macOS: open `NFCC-Companion.dmg`, drag to Applications.
- Linux: extract `NFCC-Companion.tar.gz` and run `./nfcc-companion`.

## Pairing phone ↔ PC

1. Launch the PC companion. Right-click its tray icon → **Open Dashboard…** (or type `NFCC-PC` in any terminal).
2. On phone: **Settings → Pair PC → Scan QR** using the QR on the dashboard.
3. Or: on the same Wi-Fi, **Settings → Pair PC → Auto-discover**.

Pairing stores a token locally; no cloud account.

Since v1.2.0 the phone **auto-reconnects to the last paired PC** every time the app launches. Pair once, then just use the app — the tray icon goes green within a couple of seconds of opening NFCC. If the PC moves to a new IP (DHCP renewal, different Wi-Fi), the phone's background rediscovery picks it up automatically.

On the PC side, run `NFCC-PC health` any time to verify the service is actually alive:

```
[OK  ] service    answering on :8877 — 1 device(s) connected
[OK  ] websocket  listening on :9876
[OK  ] autostart  registered in HKCU\…\Run
```

## Smart NFC tab

Three entry points.

### Routines
IF/ELSE automations. Example:
- **Morning Office** (tag on desk)
  - IF weekday 9:00–12:00 AND Wi-Fi "OfficeNet"
    - PC: Launch VS Code, Launch Tally
    - Phone: Wi-Fi ON, DND ON
  - ELSE IF weekday 13:00–14:00
    - PC: Minimize all
    - Phone: Music play
  - ELSE: Lock PC

### Tracking
- **Counter** — water, coffee, calories, pushups. Each tap adds `per_tap_amount`. Optional daily goal shows a progress ring.
- **IN / OUT toggle** — home, office, gym session. State flips on each tap. If no previous log, defaults to IN.

One tag can be paired with many trackers. Tap it once → every paired counter increments AND every paired toggle flips.

### TODOs
- Daily (with optional reminder time) or one-off.
- Streak counter holds if you complete today OR were done yesterday.
- Multiple tags per TODO — tap any of them to complete.
- One tag paired with multiple TODOs → a picker sheet shows after tap so you choose which to mark done.

## NFC Writer tab

Write common payloads to a tag:
- URL, plain text, phone, SMS, email
- Wi-Fi (SSID + password + auth type)
- Location (coordinates — pick on map or enter manually)
- Launch App (pick from installed apps)
- UPI payment (PhonePe / GPay / Paytm / BHIM / Amazon Pay)
- Business card (coming soon)

Writing from within the app stores an NDEF handle:
- `NFCC:<id>` — routine
- `NFCC_T:<id>` — tracker (from the **Write** chip on a tracker card)
- `NFCC_D:<id>` — TODO (from the **Write** chip on a TODO card)

A fresh install that imports the same tracker/TODO/routine by id will auto-pair the physical tag on its first tap.

## Launch PC App (action editor)

Picking **Launch app** in the PC action picker opens a rich picker sheet:
- **Presets** — VS Code, Cursor, Sublime, Notepad, Chrome / Edge / Firefox, Windows Terminal / PowerShell / cmd, File Explorer, Calculator, Paint, Settings, Discord, Telegram, WhatsApp, Spotify, Word, Excel, Outlook, Teams, Tally.
- **Target (optional)** — for apps that accept one (IDEs, browsers, file manager, Office), a second field lets you paste a folder path, file path, or URL. That's passed as argv[1], so `VS Code` + `C:\code\myrepo` is the exact equivalent of running `code C:\code\myrepo` on the PC.
- **Custom** — if your app isn't in the presets, drop in an alias (e.g. `obsidian`) or a full `.exe` path and optionally a target.

On the PC side this calls the companion's `launch_app` action, which resolves the alias through `APP_ALIASES` (extend in [nfcc_pc/actions/apps.py](../nfcc_pc/actions/apps.py)) and runs the app with the target as its first argument.

## Troubleshooting

**Tag not reading**
- On Android 10+, keep the screen on and NFC enabled during tap.
- Some phone cases (metal/magnetic) block NFC.

**PC not responding**
- Phone and PC must be on the **same** Wi-Fi network.
- Check the PC tray icon is green (connected).
- Firewall: allow TCP 9876 inbound on the PC.

**Streak reset**
- Streak holds if you complete today OR if yesterday was done. Skip a day = reset.

**Web preview looks empty**
- Clear browser IndexedDB for the site (DevTools → Application → IndexedDB → delete). Schema migrations require a fresh store when upgrading across versions.
