# Komit

Private, offline habit tracker in Flutter (Android first). Before any UI work, read
`docs/design/design-system.md` and follow it: Material 3 Expressive with premium iOS-like
touches, tokens from `lib/core/theme/` only, shared widgets from
`lib/features/shared/shared_widgets.dart`, Lucide icons through `KomitIcons`, Komo kept
minimal. Screen-specific notes: `docs/design/daily-loop.md`, `docs/design/habit-editor.md`.
Architecture decisions: `docs/adr/`.

- French copy says "tu".
- Releases are GitHub releases (signed arm64 APK with a sha256 digest) for the in-app updater;
  bump `version` (name and code) and `CHANGELOG.md` each time.
- Never commit `android/key.properties`, a keystore, a real backup file or `.claude/`.
- Commits use the GitHub noreply email set in the repo config; merge locally, never in the
  GitHub web UI.
