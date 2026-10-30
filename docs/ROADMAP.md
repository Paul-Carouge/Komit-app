# Roadmap

Every item below is approved. They are done one per iteration, top to bottom: the order
follows dependencies (safety net first, schema changes grouped before the features that read
them) and the one deadline (the year in review must ship before December). Update this file in
every iteration: status, decisions taken, what shipped and in which version.

Status: `todo`, `in progress`, `done (vX.Y.Z)`.

| # | Item | Status | Target version |
|---|------|--------|----------------|
| 1 | [CI and scripted release](#1-ci-and-scripted-release) | done (tooling) | none (tooling) |
| 2 | [Audit fixes and on-device update check](#2-audit-fixes-and-on-device-update-check) | in progress (released, phone check pending) | 2.3.1 |
| 2b | [Update freshness and release notes](#2b-update-freshness-and-release-notes) | in progress | 2.4.0 |
| 3 | [Year in review](#3-year-in-review) | todo | 2.5.0, before December 1 |
| 4 | [Pause and rest days](#4-pause-and-rest-days) | todo | 2.6.0 |
| 5 | [Quantity habits](#5-quantity-habits) | todo | 3.0.0 if the backup format breaks, else 2.7.0 |
| 6 | [A note on a logged day](#6-a-note-on-a-logged-day) | todo | minor |
| 7 | [Finer reminders](#7-finer-reminders) | todo | minor |
| 8 | [Per-habit widget](#8-per-habit-widget) | todo | minor |
| 9 | [Habit templates](#9-habit-templates) | todo | minor |
| 10 | [CSV export](#10-csv-export) | todo | minor |

## 1. CI and scripted release

**Why first:** every later item changes the schema or the dashboard; the project rules ask for
a green CI before merging, and none exists yet.

- GitHub Actions on every pull request and on `main`: `flutter pub get` from the lockfile,
  `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`, and a release build
  without signing (proves the Gradle checks, R8 and the manifest permission allowlist).
- A release script under `tool/` that does what README "Publish a version" does by hand:
  check a clean `main`, build the arm64 APK with `--split-debug-info`, verify with `apksigner`
  that the certificate SHA-256 matches the published one and that versionCode went up, then
  create the tag and the GitHub release from a notes file. Signing stays local: no keystore or
  password in CI.
- Acceptance: a pull request shows the checks; the script refuses a dirty tree, a wrong key or
  an unchanged versionCode; README points to the script.

**Decisions:** `.github/workflows/ci.yml` pins its actions by commit and Flutter to 3.47.7, and
also runs the Kotlin unit tests (`:app:testDebugUnitTest`; AGP 9 creates no release unit test
task). Without `android/key.properties` the release build type is left unsigned instead of
failing, which is what lets CI build it; an unsigned APK cannot be installed and the script
rejects it. `tool/release.sh` holds the certificate SHA-256 next to README's copy, reads the
previous versionCode from the latest release's tagged `pubspec.yaml`, checks the built APK with
`aapt2`, puts it in `build/release/` (ignored), and asks before tagging and publishing.

## 2. Audit fixes and on-device update check

From the 2.3.0 security audit.

- Below Android 13 (no `setRecentsScreenshotEnabled`), add `FLAG_SECURE` while the app lock is
  on, so the recent-apps thumbnail never shows habits (`AppLock.kt`, `app_lock_gate.dart`).
  A test covers the choice of flags per SDK level.
- README: stop claiming that `network_security_config.xml` protects the updater's
  `dart:io` traffic; optionally refuse non-https redirects in `app_update_service.dart`.
- Release 2.3.1 with the script from item 1, and check on a real phone that 2.3.0 finds,
  downloads, verifies and installs it. Note the result here.

**Decisions:** Dart sends both window settings in one `applyWindowProtections` call and
`windowProtectionsFor` in `AppLock.kt` picks the flags, so "Hide from screenshots" turned off
can no longer clear the `FLAG_SECURE` the lock needs below Android 13. The updater follows
redirects itself (`httpsRedirectTarget`) and refuses any that leave HTTPS, for the release
check and the APK download. ADR 0005 got a correction note instead of a new ADR.

## 2b. Update freshness and release notes

Approved on 2026-10-30, before the year in review, so users always know their app is up to date.

- Check for a new version at each launch, at most once an hour (was once a day), still only
  while the automatic check is on. Privacy screen, setting, README and ADR 0005 say so.
- Render the release notes (headings, bullets, **bold**) in the update dialog; links and
  HTML stay literal text.
- After an update installed from Komit, show once what the version brings ("Welcome to X.Y.Z").
- Settings show "Up to date · checked today at 14:32" after a check found nothing newer.
- A release notes template (`tool/release-notes-template.md`) that `tool/release.sh` checks.

**Decisions:** one hour rather than every launch, so opening and closing Komit in a row does
not hit GitHub each time. The notes shown after an update are the ones saved when the user
accepted it, so the first launch needs no network; they are dropped when another version was
installed meanwhile. The rendering is a small parser in `release_notes.dart`, not a Markdown
dependency.

## 3. Year in review

**Deadline:** in the app from December 1, shown until January 15.

- A sequence of full-screen cards narrated by Komo: success days in the year, longest streak,
  most regular weekday, best month, the habit kept longest, achievements unlocked this year.
- Computed on the phone from existing data (`domain/habit_statistics.dart`, the weekly recap
  logic); no schema change.
- An optional shareable image rendered on the phone, without habit names unless the user
  chooses to show them.
- Entry point: a card on the dashboard during the period, like the Monday recap, plus a row in
  statistics. Design through the `ux-ui-designer` agent; screen notes in `docs/design/`.
- States: a year with almost no data gets a short, kind version, not empty numbers.

## 4. Pause and rest days

**Why before quantity habits:** both change how a day counts; streaks must handle a paused day
before a day can also be "half done".

- Pause a habit for a period (holiday, illness): no reminders, no widget entry, and the paused
  days neither break nor extend the streak. Shown on the strip and the yearly grid.
- Optional rest allowance per week (for example one day) that keeps a daily streak alive.
- Schema migration (Drift), backup format version bump with older backups still importing
  (ADR 0001), streak and statistics updates with tests, reminders skip paused days.
- ADR for the counting rules.

## 5. Quantity habits

- A habit can track an amount with a unit and a daily target ("8 glasses", "20 min"): log by
  +1 steps or by typing a value; the day succeeds once the target is reached.
- Schema: a target and unit on the habit, a value on the log. Decide in an ADR whether a
  quantity habit still has objectives or replaces them, and how backups carry it.
- Dashboard button, log sheet, reminders' actions, widget, statistics and achievements all
  learn the new kind.

## 6. A note on a logged day

- An optional short text in the log sheet, shown on the day in the details screen and the
  yearly grid's day sheet. Length limit like the other texts; kept in backups.
- Comes after item 5 so the redesigned log sheet gets the field once.

## 7. Finer reminders

- Several reminder times per habit.
- An optional single evening summary listing what is left today, instead of one notification
  per habit. Lock screen still names no habit.
- Respects pauses (item 4) and quantity targets (item 5).

## 8. Per-habit widget

- A widget for one chosen habit: its recent weeks as a grid and a log button, in the habit's
  color. Same lock rules as the "Today" widget (no habits while the app is locked).

## 9. Habit templates

- When creating a habit, a few ready-made starting points (exercise, reading, water,
  meditation...) with icon, color, schedule and objectives or quantity filled in. Also offered
  during onboarding.

## 10. CSV export

- Export the history as CSV (one row per habit and day) for spreadsheets, next to the backup
  export. Last, so the columns include pauses, quantities and notes.

## Shipped

Record each finished item here: date, version, pull request or commit, and anything left out.

- 2026-10-30, item 1, no app version: CI workflow and `tool/release.sh`, branch
  `chore/ci-and-scripted-release`. The script's first real run is the 2.3.1 release (item 2).
