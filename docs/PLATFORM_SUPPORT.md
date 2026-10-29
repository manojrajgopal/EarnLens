# Platform support

| Capability | Android | iOS | Web |
|---|---|---|---|
| App, calculations, history, settings | ✅ built & tested | ✅ built unsigned on a GitHub-hosted Mac (`build-ios` CI job); install from Windows per [IOS_INSTALL.md](IOS_INSTALL.md) | ✅ built |
| Storage | SQLite (app sandbox) | SQLite (app sandbox) | SQLite WASM in OPFS/IndexedDB — can be cleared, per-browser |
| PIN lock | ✅ Keystore-backed secure storage | ✅ Keychain | ✅ WebCrypto-encrypted localStorage (weaker; no hardware backing) |
| Biometrics | ✅ fingerprint/face | ✅ Face ID/Touch ID (`NSFaceIDUsageDescription` set) | ❌ not offered |
| Local notifications | ✅ scheduled, survive reboot; may be inexact | ✅ scheduled | ⚠️ only while a tab is open |
| Home-screen widget | ✅ native `AppWidgetProvider`, ~30 min refresh | ❌ deferred — WidgetKit extension needs Xcode | n/a |
| Privacy screen | ✅ FLAG_SECURE + overlay | overlay | overlay |
| Backup/restore, CSV | ✅ system document picker / share | ✅ Files / share sheet | ✅ download / file input |

## Requirements

- Flutter 3.47.x stable (Dart 3.13), JDK 17–21 for Android builds (JDK 26 is too new for Gradle;
  run `flutter config --jdk-dir=<jdk-21>`).
- Android: minSdk 24, core library desugaring enabled, AppCompat themes.
- iOS: Xcode 16+, iOS 13+.

## Android

```bash
flutter build apk --release
```

Release signing currently uses the debug key (so `--release` runs locally). Before publishing,
create a keystore and add a `signingConfigs.release` block to `android/app/build.gradle.kts`.

Home-screen widget: values are precomputed by the app for 30-minute checkpoints over the next 24 h
(exact engine values); the widget shows the latest checkpoint and "Estimate as of HH:mm". Android
limits refreshes to about every 30 minutes, so no per-second claim is made. If the app is not opened
for more than a day the widget asks the user to open it.

## iOS

```bash
flutter build ios --release --no-codesign   # on macOS; CI does this and packages EarnLens.ipa
```

Plugins are linked through Swift Package Manager (CocoaPods is used automatically for any plugin
that needs it). From Windows, get `EarnLens.ipa` from the CI run's artifacts and sideload it —
see [IOS_INSTALL.md](IOS_INSTALL.md). Icons are opaque (App Store requirement) and the share sheet
is anchored for iPad popovers. WidgetKit widget is deferred: it requires adding a
Widget Extension target and App Group in Xcode; the Dart side (`HomeWidgetBridge`) is designed for
it (`home_widget` supports iOS app groups).

## Web

```bash
flutter build web --release
```

`web/sqlite3.wasm` and `web/drift_worker.js` must match the resolved `sqlite3` and `drift`
package versions (currently 3.5.2 and 2.35.3) — re-download them from the respective GitHub
releases when upgrading. The server must serve `.wasm` as `application/wasm`; for best storage
(OPFS) serve with `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`. Without them Drift falls back to IndexedDB.

Browser data is not a permanent database: export backups regularly.
