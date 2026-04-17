# NFCC — NFC tag data format

NFCC tags store a **single NDEF message**. The app uses the tag's UID as the primary key; the NDEF payload is a fallback for cross-install portability.

## NDEF record types

| Record | URI prefix / MIME       | Payload                                               |
| ------ | ----------------------- | ----------------------------------------------------- |
| URI    | `https://`, `tel:`, `mailto:` etc. | Free-form URL.                                        |
| Text   | —                       | Plain UTF-8 text.                                     |
| MIME   | `application/com.nfccontrol.nfcc` | App routine handle. Value: `NFCC:<automation_id>`.    |
| Wi-Fi  | `application/vnd.wfa.wsc` | Wi-Fi Simple Configuration credentials.              |
| GeoURI | `geo:<lat>,<lng>`       | Coordinates.                                          |

## Routine tag

When the mobile app writes a routine, it creates two records:

1. **MIME** `application/com.nfccontrol.nfcc` → payload `NFCC:<id>`
2. **AAR** (Android Application Record) `com.nfccontrol.nfcc` → opens the app on tap

The AAR ensures the device routes the tap to NFCC even if the user hasn't opened the app recently.

## Supported chips

| Chip              | Capacity | Used for                  |
| ----------------- | -------- | ------------------------- |
| NTAG213           | 144 B    | Routines, URLs            |
| NTAG215           | 504 B    | Business cards, long NDEF |
| NTAG216           | 888 B    | Rich payloads             |
| Mifare Ultralight | 64 B     | UID-only bindings         |

## UID as primary key

Trackers and TODOs are keyed on the tag **UID**, not NDEF content. That means:
- Blank tags work — just scan once to register the UID, then pair.
- Overwriting NDEF does not break tracker/TODO bindings.
- The UID is the hex string exposed by Android's `Tag` object.

## Security note

NFC is a short-range, unauthenticated radio link. Don't store secrets (passwords, OTPs) on a tag you don't physically control.
