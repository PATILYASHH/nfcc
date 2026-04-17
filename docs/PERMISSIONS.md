# Android permissions rationale

Every permission in `nfcc_mobile/android/app/src/main/AndroidManifest.xml` is listed here with **why** the app requests it. F-Droid reviewers, users, and auditors — please read this to confirm NFCC does not quietly collect or exfiltrate anything.

## NFC

| Permission | Why |
| --- | --- |
| `NFC` | Read and write NFC tags — the entire purpose of the app. |
| *feature* `android.hardware.nfc` (required) | App is unusable on devices without NFC. |

## Network (LAN only)

| Permission | Why |
| --- | --- |
| `INTERNET` | Open a WebSocket to the user's own paired PC on the same Wi-Fi. The app does **not** contact any third-party server except OpenStreetMap tiles when the user actively opens the location map picker. |
| `ACCESS_WIFI_STATE` | Read current Wi-Fi SSID to evaluate the "connected to Wi-Fi X" condition in automations. |
| `CHANGE_WIFI_STATE` | Phone action: toggle Wi-Fi on/off. |
| `ACCESS_NETWORK_STATE` | Detect loss of LAN connectivity to the PC companion. |
| `CHANGE_NETWORK_STATE` | Phone action: toggle mobile data. |

## Location

| Permission | Why |
| --- | --- |
| `ACCESS_COARSE_LOCATION` | **Android 10+ requirement**: reading the current Wi-Fi SSID now requires location permission. Used only to evaluate Wi-Fi-based automation conditions. |
| `ACCESS_FINE_LOCATION` | Same rationale, needed on some OEM ROMs. |

The app never queries GPS coordinates, never stores location data, and never sends location off-device.

## Bluetooth

| Permission | Why |
| --- | --- |
| `BLUETOOTH` | Legacy Bluetooth permission for Android ≤ 11. |
| `BLUETOOTH_ADMIN` | Phone action: toggle Bluetooth. |
| `BLUETOOTH_CONNECT` | Android 12+ — detect paired Bluetooth devices for automation conditions. |
| `BLUETOOTH_SCAN` | Android 12+ — enumerate paired devices for the condition picker. |

## System actions

| Permission | Why |
| --- | --- |
| `MODIFY_AUDIO_SETTINGS` | Phone action: change ringer mode / volume. |
| `ACCESS_NOTIFICATION_POLICY` | Phone action: toggle Do Not Disturb. |
| `WRITE_SETTINGS` | Phone action: change screen brightness. User is prompted by the system to grant this in Settings — the app cannot set it silently. |
| `VIBRATE` | Haptic feedback on every tag tap (success = 2 short, failure = 1 long). |
| `CAMERA` | Scan pairing QR code for the optional PC companion. |
| *feature* `android.hardware.camera.flash` (optional) | Phone action: toggle flashlight. |
| `QUERY_ALL_PACKAGES` | "Launch App" tag action — show the user a picker of their installed apps so they can pick one to launch on tap. The app only reads app labels + package names; it never uploads the list anywhere. |

# Anti-features declaration

Answers to the categories in https://f-droid.org/en/docs/Anti-Features/.

| Anti-feature | Applies? | Notes |
| --- | --- | --- |
| **Ads** | ❌ No | No advertising SDK, no in-app ads. |
| **Tracking** | ❌ No | No analytics, no crash reporter, no telemetry. |
| **NonFreeNet** | ❌ No | The only networking is (1) optional LAN WebSocket to the user's own PC companion, and (2) OpenStreetMap tiles (free/libre) when the user opens the map picker. |
| **NonFreeAdd** | ❌ No | No optional non-free add-on features. |
| **NonFreeDep** | ❌ No | No dependency on any proprietary library. See [DEPENDENCIES.md](DEPENDENCIES.md). |
| **NonFreeAssets** | ❌ No | All icons are Material Icons (Apache-2.0) or Cupertino Icons (MIT). No proprietary art. |
| **UpstreamNonFree** | ❌ No | Entire source tree is MIT. |
| **DisabledAlgorithm** | ❌ No | No crypto-downgrade. |
| **KnownVuln** | ❌ No | All dependencies on current maintained versions. |
| **NSFW** | ❌ No | |

If any of these change in a future release, update this file in the same commit and add the correct `AntiFeatures:` key to `.fdroid/com.nfccontrol.nfcc_mobile.yml` *before* submitting the release to F-Droid.
