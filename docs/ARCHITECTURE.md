# NFCC — Architecture

```
┌─────────────┐      ┌──────────────────────┐      ┌────────────────────────┐
│  NFC Tag    │─tap─▶│  Phone (Flutter)     │─WS──▶│  PC Companion (Python) │
│  UID only   │      │  nfcc_mobile         │      │  nfcc_pc               │
└─────────────┘      └─────────┬────────────┘      └────────────┬───────────┘
                               │                                │
                               │ local SQLite                   │ Windows API
                               ▼                                │ pycaw / pyautogui
                        ┌────────────┐                          │
                        │  nfcc.db   │                          ▼
                        └────────────┘                  ┌──────────────┐
                                                        │   PC state   │
                                                        └──────────────┘
```

## Why the tag only stores a UID

The tag never holds automation data. The mobile app keeps the full automation/tracker/todo definitions in `nfcc.db` and looks them up by the UID that the NFC chip emits. This means:

- Stickers stay cheap (NTAG213, 180 bytes is plenty).
- Re-assigning a tag doesn't require re-writing it.
- Privacy — a lost tag only reveals its UID.

Exception: when you write a routine to a tag, the app also stores `NFCC:<automation_id>` in an NDEF record so a fresh install can resolve it.

## Components

### `nfcc_mobile/` (Flutter Android)
- Reads/writes NFC tags (`nfc_manager` package).
- Evaluates automation conditions (time/day/wifi SSID/bluetooth device).
- Dispatches actions to the phone via Android platform channels.
- Talks to the PC over WebSocket (`web_socket_channel`).
- Persists state in SQLite (`sqflite`).
- Web preview target uses `sqflite_common_ffi_web` (IndexedDB-backed).

### `nfcc_pc/` (Python system tray)
- Discovers itself over UDP (port 9877) so the phone can auto-find it.
- Accepts a WebSocket connection on port 9876 with a pairing token.
- Executes 32 actions: media keys, window management, launch app, screenshot, clipboard, etc.
- Volume control via `pycaw`, keypresses via platform channel.
- Runs as tray icon via `pystray`.

### `nfcc-web/` (Next.js)
- Landing page with OS-specific download buttons.
- Hosts published business cards (Vercel KV).

## Data model (mobile)

Six core tables plus three for the tracking/todo layer:

| Table              | Purpose                                            |
| ------------------ | -------------------------------------------------- |
| `nfc_tags`         | Discovered UIDs + scan count + nickname            |
| `automations`      | Routine definitions                                |
| `condition_branches` | IF/ELSE IF/ELSE branches per automation          |
| `action_items`     | Phone and PC actions per branch                    |
| `tag_scan_logs`    | History of tag taps + outcome                      |
| `paired_pcs`       | Known PC endpoints                                 |
| `trackers`         | Counter + IN/OUT toggle definitions                |
| `tracker_tags`     | Many-to-many tag ↔ tracker                        |
| `tracker_logs`     | Each tap appends one row                           |
| `todos`            | Daily/one-off tasks with streak + reminder time    |
| `todo_tags`        | Many-to-many tag ↔ todo                           |
| `todo_completions` | Daily completion dedup'd by `date_key`             |

See [`nfcc_mobile/lib/services/database_service.dart`](../nfcc_mobile/lib/services/database_service.dart) for the schema.

## Tap dispatch flow

1. Android NFC intent fires, `NfcIntentService` forwards UID + NDEF to `SilentExecutor`.
2. `_dispatchTrackers(uid)` — for each paired tracker:
   - Counter → append `per_tap_amount`.
   - Toggle → look up last state, flip IN↔OUT.
3. `_dispatchTodos(uid)` — toggle today's completion (silent) or, in foreground, show `TodoTapSheet` so the user can pick.
4. Automation lookup via `NFCC:<id>` NDEF or `tag_uid` DB link → evaluate branches → execute actions.
5. Haptic: 2x short = success, 1x long = failure.
6. Scan log written.

## Local-only networking

All phone↔PC traffic is LAN. No relay servers. Port 9876 (WebSocket) and 9877 (UDP discovery) are bound to `0.0.0.0`. Pairing token is an opaque UUID generated on first run and never leaves the devices.
