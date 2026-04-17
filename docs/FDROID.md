# Publishing NFCC to F-Droid

NFCC is designed to meet F-Droid's inclusion criteria:
- MIT licensed, source code on a public git host.
- No proprietary dependencies (no Firebase, Google Play Services, analytics, or ads).
- No user tracking of any kind.
- Reproducible Flutter/Gradle build.

This guide walks you through submitting NFCC to the official F-Droid repository (`f-droid.org`).

---

## 1. Checklist before submitting

Before you open the merge request, confirm each of these on `main`:

- [ ] `nfcc_mobile/pubspec.yaml` `version:` is bumped (e.g. `1.0.0+1`).
- [ ] `nfcc_mobile/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt` exists.
- [ ] A signed Git tag exists for the version — e.g. `v1.0.0`.
- [ ] GitHub Actions `Android APK` workflow passes for that tag.
- [ ] No proprietary libraries added to `pubspec.yaml` (search for `firebase_`, `google_mobile_ads`, `crashlytics`, etc.).
- [ ] `AndroidManifest.xml` lists only permissions the app actually uses.
- [ ] `fastlane/metadata/android/en-US/images/icon.png` is present (512×512).
- [ ] Screenshots in `.../images/phoneScreenshots/` (3–8 recommended).

## 2. Tag the release

```bash
git tag -a v1.0.0 -m "NFCC 1.0.0"
git push origin v1.0.0
gh release create v1.0.0 --generate-notes
```

The `android.yml` and `pc-windows.yml` workflows will attach the APK and the Windows EXE to the GitHub Release automatically.

## 3. Fork `fdroiddata`

F-Droid's metadata lives in a GitLab repository:

```bash
# 1. Open https://gitlab.com/fdroid/fdroiddata and click "Fork"
# 2. Clone your fork
git clone https://gitlab.com/<your-username>/fdroiddata.git
cd fdroiddata
git checkout -b add-nfcc
```

## 4. Copy our build recipe

Copy `.fdroid/com.nfccontrol.nfcc_mobile.yml` from this repository into:

```
fdroiddata/metadata/com.nfccontrol.nfcc_mobile.yml
```

Edit if needed — mainly `Builds[*].commit` should match the tag you just pushed, and `CurrentVersion` / `CurrentVersionCode` should match `pubspec.yaml`.

## 5. Lint locally (optional but recommended)

Install `fdroidserver`:

```bash
pip install fdroidserver
cd fdroiddata
fdroid lint com.nfccontrol.nfcc_mobile
fdroid readmeta
fdroid rewritemeta com.nfccontrol.nfcc_mobile
```

Fix anything it complains about.

## 6. Open the merge request

```bash
cd fdroiddata
git add metadata/com.nfccontrol.nfcc_mobile.yml
git commit -m "New app: com.nfccontrol.nfcc_mobile (NFCC)"
git push origin add-nfcc
```

Then on GitLab, open a Merge Request from your fork's `add-nfcc` branch into `fdroid/fdroiddata:master`.

Title it: **New app: NFCC**

Fill in the MR description template. Mention:
- License (MIT)
- Upstream URL (https://github.com/PATILYASHH/nfcc)
- Why it's useful
- That there are no anti-features

## 7. Review cycle

F-Droid maintainers will:
1. Run `fdroid lint` — fix any issues they flag.
2. Attempt a reproducible build on the F-Droid buildserver.
3. Ask for changes if the build fails or metadata is off.

This can take anywhere from a few days to a couple of weeks. Once merged, the build server produces a signed APK and NFCC appears on https://f-droid.org/packages/com.nfccontrol.nfcc_mobile/.

## 8. Shipping updates

For every new version:

1. Bump `nfcc_mobile/pubspec.yaml` `version:` (both `versionName` and `versionCode`).
2. Add `fastlane/metadata/android/en-US/changelogs/<new-versionCode>.txt`.
3. Tag (`v1.0.1`), push, create a GitHub Release.
4. With `AutoUpdateMode: Version` and `UpdateCheckMode: Tags` set in our recipe, F-Droid's updater picks up new tags automatically — no MR required for each release.

## Anti-features review

F-Droid flags apps that have any of these. NFCC does **not**:

- **NonFreeNet** — optional LAN WebSocket to the user's own PC. No third-party service.
- **Tracking** — no analytics, no crash reporting SDKs, no telemetry.
- **NonFreeAdd** — no ads.
- **NonFreeAssets** — icons/fonts shipped are Flutter's stock Material icons (Apache 2.0).
- **UpstreamNonFree** — entire source is MIT.

If you add a dependency in the future, check its license before merging.
