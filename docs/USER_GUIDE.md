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

1. Launch the PC companion. Right-click its tray icon → **Show QR**.
2. On phone: **Settings → Pair PC → Scan QR**.
3. Or: on the same Wi-Fi, **Settings → Pair PC → Auto-discover**.

Pairing stores a token locally; no cloud account.

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

Writing an automation or routine stores `NFCC:<id>` as an NDEF record. Any NFCC install can resolve it.

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
