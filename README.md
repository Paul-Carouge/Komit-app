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
flutter analyze
flutter test
```

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
- **Formats:** v2 (this app) and v1 (files exported by the original Komit app).

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

Komit has no account and no analytics. At each launch it asks
`api.github.com` for the latest release, which exposes the device IP address to GitHub.
Exported backups are plain JSON: keep them somewhere private.

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
2. Add the version to `CHANGELOG.md`.
3. Build and publish:

```sh
flutter build apk --release --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk komit-vX.Y.Z.apk
gh release create vX.Y.Z komit-vX.Y.Z.apk --title "Komit X.Y.Z" --notes-file <notes.md>
```

The release notes are what users see in the in-app update dialog.
