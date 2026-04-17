# Contributing to NFCC

Thanks for your interest in the project. This file covers the essentials.

## Development setup

### Mobile (Flutter)
```bash
cd nfcc_mobile
flutter pub get
flutter run   # Android device or emulator
```
Tree-shaking must be disabled because the app uses dynamic `IconData`:
```bash
flutter build apk --release --no-tree-shake-icons
```

### PC companion (Python)
```bash
cd nfcc_pc
python -m venv .venv
.venv/Scripts/activate        # or source .venv/bin/activate on unix
pip install -r requirements.txt
python main.py
```

### Landing page (Next.js)
```bash
cd nfcc-web
npm install
npm run dev
```

## Branches

- `main` — always green. Protected. All CI workflows must pass.
- Feature branches — `feat/<short-name>`, open a PR into `main`.
- Hotfix — `fix/<short-name>`.

## Commit style

```
<scope>: <imperative summary>

Longer explanation if the why isn't obvious from the diff.
```
Scopes used in this repo: `mobile`, `pc`, `web`, `docs`, `ci`, `meta`.

## Pull requests

- Small, focused PRs beat mega-diffs.
- Update `docs/` when behavior changes.
- CI must go green: Android build, Windows build, macOS/Linux build, Web build.
- Screenshots for UI changes.

## Code style

- Dart: `flutter analyze` must be clean.
- Python: 4-space indent, type hints where reasonable.
- No unused imports, no commented-out code.

## Reporting issues

Use the issue templates. Include:
- OS / Android version / PC OS
- NFCC version (see Settings)
- Steps to reproduce
- Logs from `adb logcat` (phone) or `nfcc_pc/logs/` (PC)
