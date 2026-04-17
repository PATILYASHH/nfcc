# NFCC — NFC Control

> Tap an NFC tag → run automations, log habits, and complete to-dos on your phone **and** PC.

<p align="left">
  <a href="https://github.com/PATILYASHH/nfcc/actions/workflows/android.yml"><img alt="Android APK" src="https://github.com/PATILYASHH/nfcc/actions/workflows/android.yml/badge.svg"></a>
  <a href="https://github.com/PATILYASHH/nfcc/actions/workflows/pc-windows.yml"><img alt="Windows EXE" src="https://github.com/PATILYASHH/nfcc/actions/workflows/pc-windows.yml/badge.svg"></a>
  <a href="https://github.com/PATILYASHH/nfcc/actions/workflows/ios.yml"><img alt="iOS (unsigned)" src="https://github.com/PATILYASHH/nfcc/actions/workflows/ios.yml/badge.svg"></a>
  <a href="https://github.com/PATILYASHH/nfcc/actions/workflows/web.yml"><img alt="Web Preview" src="https://github.com/PATILYASHH/nfcc/actions/workflows/web.yml/badge.svg"></a>
  <a href="https://github.com/PATILYASHH/nfcc/actions/workflows/fdroid-check.yml"><img alt="F-Droid check" src="https://github.com/PATILYASHH/nfcc/actions/workflows/fdroid-check.yml/badge.svg"></a>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <img alt="No tracking" src="https://img.shields.io/badge/tracking-none-success">
  <img alt="No ads" src="https://img.shields.io/badge/ads-none-success">
</p>

NFCC turns a cheap NFC sticker into a universal remote. One tap can launch apps on your PC, toggle phone state, log a glass of water, clock in at work, or tick off a daily TODO — and the same tag can do all of that at once.

---

## ✨ Features

- **Routines** — IF/ELSE branches over time, day, Wi-Fi, and Bluetooth. 28 phone actions, 32 PC actions.
- **Tracking** — counters (water, coffee, calories, reps) and state-aware IN/OUT toggles (home, office, gym).
- **TODOs** — daily with streak tracking or one-off tasks. Optional reminder time per task.
- **One tag, many jobs** — a single tag can fire a routine, log multiple trackers, and complete several TODOs in one tap.
- **Local-first** — everything runs on your LAN. No cloud account, no subscription.
- **NFC Writer** — write URLs, Wi-Fi credentials, phone numbers, SMS, email, location, UPI payment links and more.

## 📦 Downloads

| Platform        | Artifact                  | Where                                                                 |
| --------------- | ------------------------- | --------------------------------------------------------------------- |
| 📱 Android       | `app-release.apk`         | [Latest release](https://github.com/PATILYASHH/nfcc/releases/latest) |
| 🪟 Windows       | `NFCC-Companion.exe`      | [Latest release](https://github.com/PATILYASHH/nfcc/releases/latest) |
| 🍎 iOS (preview) | `NFCC-Runner.app.zip`     | Actions artifacts · unsigned, for developer sideload                 |
| 🍏 macOS         | *planned*                 | Needs cross-platform audio refactor                                   |
| 🐧 Linux         | *planned*                 | Needs cross-platform audio refactor                                   |
| 🌐 Web preview   | live demo                 | https://patilyashh.github.io/nfcc/                                   |

Every push to `main` uploads build artifacts to the corresponding Actions run. Creating a GitHub Release attaches the Android APK and Windows EXE automatically.

## 🏗 Repository layout

```
nfcc/
├─ nfcc_mobile/   Flutter Android app (phone, web preview)
├─ nfcc_pc/       Python system-tray companion (Windows/macOS/Linux)
├─ nfcc-web/      Next.js landing page + business-card host
├─ docs/          Architecture, user guide, NFC data format
└─ .github/       CI/CD build pipelines
```

## 🚀 Quick start

### Phone
1. Download the latest APK from [Releases](https://github.com/PATILYASHH/nfcc/releases/latest).
2. Install, allow NFC + Location + Bluetooth permissions.
3. Open **NFC Writer**, pick an action, tap a tag to write.

### PC companion
Windows:
```
NFCC-Companion.exe
```
macOS / Linux:
```
python3 nfcc_pc/main.py
```
Pair with the phone via the QR code in **Settings → Pair PC**.

### Build from source
```bash
# Mobile
cd nfcc_mobile
flutter pub get
flutter build apk --release --no-tree-shake-icons

# PC companion
cd nfcc_pc
pip install -r requirements.txt
python main.py

# Landing page
cd nfcc-web
npm install && npm run dev
```

## 📚 Documentation

- [Architecture overview](docs/ARCHITECTURE.md) — how phone, PC, and tag talk to each other
- [User guide](docs/USER_GUIDE.md) — routines, tracking, TODOs, tag pairing
- [NFC data format](docs/NFC_DATA_FORMAT.md) — what's written to a tag
- [Android permissions rationale](docs/PERMISSIONS.md) — every permission justified + anti-features declaration
- [Dependency audit (FOSS SBOM)](docs/DEPENDENCIES.md) — every package + license
- [Publishing to F-Droid](docs/FDROID.md) — submission steps for `fdroiddata`
- [Contributing](CONTRIBUTING.md)

## 🤝 Contributing

Pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). Every PR must pass the Android, PC, and Web workflows before merge.

## 📜 License

MIT © [Yash Patil](https://github.com/PATILYASHH). See [LICENSE](LICENSE).
