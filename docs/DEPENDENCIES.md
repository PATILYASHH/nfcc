# NFCC — dependency audit (F-Droid SBOM)

Every runtime dependency of the Android app. All are **FOSS** (OSI-approved license), **no** analytics / ads / proprietary cloud SDKs.

Run `flutter pub deps` to see the full transitive tree.

## Direct runtime dependencies

| Package                | Version | License        | Purpose                                    |
| ---------------------- | ------- | -------------- | ------------------------------------------ |
| `nfc_manager`          | ^4.0.0  | BSD-3-Clause   | NFC read/write/format                      |
| `provider`             | ^6.1.2  | MIT            | App state management                       |
| `sqflite`              | ^2.3.0  | BSD-2-Clause   | Local SQLite database                      |
| `sqflite_common_ffi_web` | ^1.1.1 | MIT            | SQLite on web (preview build only)         |
| `path`                 | ^1.9.0  | BSD-3-Clause   | Path joining                               |
| `path_provider`        | ^2.1.5  | BSD-3-Clause   | Platform-specific storage paths            |
| `web_socket_channel`   | ^2.4.0  | BSD-3-Clause   | LAN WebSocket to optional PC companion     |
| `http`                 | ^1.6.0  | BSD-3-Clause   | Local HTTP (card publish, PC health check) |
| `qr_flutter`           | ^4.1.0  | BSD-3-Clause   | Render QR codes for PC pairing             |
| `mobile_scanner`       | ^5.0.0  | BSD-3-Clause   | Scan pairing QR codes                      |
| `flutter_animate`      | ^4.5.0  | MIT            | Declarative UI animations                  |
| `permission_handler`   | ^11.3.0 | MIT            | Runtime permission prompts                 |
| `installed_apps`       | ^1.5.0  | BSD-3-Clause   | List installed apps for Launch App action  |
| `uuid`                 | ^4.3.3  | MIT            | Generate pairing tokens                    |
| `cupertino_icons`      | ^1.0.8  | MIT            | iOS-style icons (Flutter stock)            |
| `shared_preferences`   | ^2.5.5  | BSD-3-Clause   | Tiny local KV store                        |
| `flutter_map`          | ^8.3.0  | BSD-3-Clause   | Map picker for location writes             |
| `latlong2`             | ^0.9.1  | Apache-2.0     | LatLng data type for flutter_map           |

## Dev dependencies (not shipped)

| Package         | License | Purpose      |
| --------------- | ------- | ------------ |
| `flutter_lints` | BSD-3   | Static lints |
| `flutter_test`  | BSD-3   | Unit tests   |

## Third-party tiles

`flutter_map` is configured to use **OpenStreetMap** tiles via `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. These are the community-run, free-to-use tiles under ODbL. No API key, no account.

This IS a network call to a third-party server when the map picker is opened. The F-Droid anti-feature **NonFreeNet** is **not** triggered because the server and its data are free and open. F-Droid has many apps using OSM the same way (OsmAnd, StreetComplete, etc.).

## Fonts and assets

- Material Icons ship with Flutter (Apache-2.0).
- `CupertinoIcons.ttf` (MIT) ships with the `cupertino_icons` package.
- No custom fonts, no proprietary illustrations.

## What is NOT in this app

- ❌ Firebase / Google Play Services (any module)
- ❌ Crashlytics / Sentry / any crash reporter
- ❌ Google Analytics / Mixpanel / Amplitude / any analytics
- ❌ AdMob / any ad SDK
- ❌ Facebook SDK
- ❌ Any proprietary closed-source library

If anyone proposes adding a non-FOSS dependency, reject the PR or move the feature behind a build flag so F-Droid can build without it.
