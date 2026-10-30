# Komit

Habit tracker where every day of every habit gets one outcome you define yourself
(e.g. "2-5 km", "Tired", "No spend"), shown as a yearly grid, with streaks,
statistics, daily reminders and a notes space.

Android first; the Flutter code also targets iOS but is not released there.

## Prerequisites

- Flutter 3.47+ (Dart 3.13+)
- Android SDK, JDK 17+ (the one bundled with Android Studio works)

## Run

```sh
flutter pub get
flutter run
```

Drift and localization code is generated and committed. After changing a table in
`lib/data/database/app_database.dart`, regenerate it:

```sh
dart run build_runner build
```

## Test

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
(cd android && ./gradlew :app:testDebugUnitTest)
```

GitHub Actions (`.github/workflows/ci.yml`) runs these checks and an unsigned release build on
every pull request and on `main`; merge only when they are green.

To check the import of a real backup from the original app without committing it
(it holds personal data):

```sh
KOMIT_LEGACY_BACKUP=/path/to/komit_backup.json flutter test test/data/backup_import_test.dart
```

## Architecture

| Layer | Folder | Notes |
| --- | --- | --- |
| Presentation | `lib/features/` | One folder per screen, Riverpod providers in `lib/providers.dart` |
| Domain | `lib/domain/` | Pure functions: streaks, yearly statistics |
| Data | `lib/data/` | Drift database, repositories, backup codec |
| Services | `lib/services/` | Reminders, in-app updates |

Decisions are recorded in [`docs/adr/`](docs/adr).

## Backups

- **Export / import:** Settings → Data & storage. Import replaces everything, in one
  transaction, after showing what the file contains.
- **Formats:** v2 (this app), v2 sealed with a passphrase (`komit-encrypted`), and v1
  (files exported by the original Komit app).
- **Automatic backups:** Settings → Data & storage → "Restore an automatic backup".

## Release

Releases are APKs published on GitHub Releases; the app checks the latest release at
launch and can install it after verifying its SHA-256.

### Verify a downloaded APK

Official APKs are signed with this certificate (SHA-256):

```
7B:86:00:AA:80:99:47:6F:8B:1D:C4:29:05:79:38:1D:24:68:AF:51:5E:32:6B:7B:07:4E:3C:4B:5E:6B:F9:FD
```

```sh
apksigner verify --print-certs komit-vX.Y.Z.apk
```

### Privacy

Komit has no account, no ads and no analytics; the in-app screen Settings → Privacy & security
→ "What stays on your phone" explains the points below to users. See
[ADR 0005](docs/adr/0005-on-device-privacy-backups-and-encryption.md) for the reasons.

- **Network:** only the update check, at most once a day and only while "Check for updates
  automatically" is on, asks `api.github.com` for the latest release (GitHub sees the
  device IP address); an accepted update is downloaded from `github.com`. Both requests use
  `dart:io`, which ignores Android's network security config but trusts only the system
  certificate store, never user-installed authorities, and checks host names (no pinning).
  The updater starts only from HTTPS GitHub URLs and refuses any redirect away from HTTPS
  (`lib/services/app_update_service.dart`). `res/xml/network_security_config.xml` applies
  the same rules to platform networking, which Komit itself does not use.
- **Android backups:** cloud backups exclude every file; device-to-device transfers keep
  everything on Android 9 and later (`res/xml/data_extraction_rules.xml`,
  `res/xml*/backup_rules.xml`).
- **Automatic backups:** v2 snapshots in app storage (`files/backups`) before every import or
  restore, before an update install and daily when the data changed; the 10 most recent
  are kept and can be restored from Settings.
- **Exports:** plain JSON by default; optionally sealed with a passphrase
  (PBKDF2-HMAC-SHA256, AES-256-GCM, `komit-encrypted` envelope).
- **App lock:** optional fingerprint, face or screen lock at launch and after a minute in
  the background. While it is on, the recent apps card is blank: Android 13+ hides the
  screenshot, older versions set `FLAG_SECURE`. "Hide from screenshots" sets `FLAG_SECURE`.
- **Permissions:** the release build fails when the merged manifest requests a permission
  outside `releaseManifestAllowedPermissions` in `android/app/build.gradle.kts`
  (`./gradlew :app:verifyReleaseManifest`).

### Release signing

Every release must be signed with the same key, otherwise Android refuses the update.
The key is **not** in the repository:

- keystore: `~/.android/komit-release.jks`
- passwords: `android/key.properties` (git-ignored)

```properties
storeFile=/Users/<you>/.android/komit-release.jks
storePassword=…
keyAlias=komit
keyPassword=…
```

Back up both files somewhere safe: losing them means users must uninstall and reinstall.

### Publish a version

1. Bump `version:` in `pubspec.yaml` (SemVer, then `+` build number, incremented every release).
2. Add the version to `CHANGELOG.md`, merge to `main` and push.
3. Write the release notes to a file outside the repository, then from an up-to-date `main`:

```sh
tool/release.sh <notes.md>
```

The script refuses a dirty tree, a branch other than `main` or one behind `origin/main`, an
existing tag and a version missing from `CHANGELOG.md`. It builds the arm64 APK with
`--split-debug-info=build/symbols/vX.Y.Z`, checks with `apksigner` that it is signed with the
published certificate only and with `aapt2` that its versionCode is above the latest release's,
then asks before creating the tag and the GitHub release with `build/release/komit-vX.Y.Z.apk`.
GitHub publishes the asset's SHA-256 digest that the in-app updater checks.

The release notes are what users see in the in-app update dialog.

`--split-debug-info` moves the Dart debug symbols out of the APK (1.4 MB smaller). Keep
`build/symbols/vX.Y.Z/app.android-arm64.symbols` with the keystore backup: without it, the stack
traces of that version's error log cannot be read
(`flutter symbolize -d app.android-arm64.symbols -i <trace.txt>`).

To check what takes space: `flutter build apk --release --analyze-size --target-platform android-arm64`.
Native libraries stay uncompressed in the APK (no `useLegacyPackaging`): compressing them would
shrink the download from about 22.6 MB to about 11 MB, but Android would then extract 21 MB of
libraries at install, so the app would take about 32 MB on the phone instead of 22.6 MB and
install more slowly.
