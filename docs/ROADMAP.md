# Roadmap

Every item below is approved. They are done one per iteration, top to bottom: the order
follows dependencies (safety net first, schema changes grouped before the features that read
them) and the one deadline (the year in review must ship before December). Update this file in
every iteration: status, decisions taken, what shipped and in which version.

Status: `todo`, `in progress`, `done (vX.Y.Z)`.

| # | Item | Status | Target version |
|---|------|--------|----------------|
| 1 | [CI and scripted release](#1-ci-and-scripted-release) | done (tooling) | none (tooling) |
| 2 | [Audit fixes and on-device update check](#2-audit-fixes-and-on-device-update-check) | done (v2.3.1) | 2.3.1 |
| 2b | [Update freshness and release notes](#2b-update-freshness-and-release-notes) | done (v2.4.0) | 2.4.0 |
| 3 | [Year in review](#3-year-in-review) | done (v2.5.0) | 2.5.0, before December 1 |
| 4 | [Pause and rest days](#4-pause-and-rest-days) | done (v2.6.0) | 2.6.0 |
| 5 | [Quantity habits](#5-quantity-habits) | done (v2.8.0) | 2.8.0 |
| 6 | [A note on a logged day](#6-a-note-on-a-logged-day) | todo | minor |
| 7 | [Finer reminders](#7-finer-reminders) | todo | minor |
| 8 | [Per-habit widget](#8-per-habit-widget) | todo | minor |
| 9 | [Habit templates](#9-habit-templates) | todo | minor |
| 10 | [CSV export](#10-csv-export) | todo | minor |
| 11 | [Consistency score](#11-consistency-score) | todo | minor |
| 12 | [Habit groups](#12-habit-groups) | todo | minor |
| 13 | [Habits to quit](#13-habits-to-quit) | todo | minor |
| 14 | [Challenges](#14-challenges) | todo | minor |
| 15 | [Month calendar of all habits](#15-month-calendar-of-all-habits) | todo | minor |
| 16 | [Trends and correlations](#16-trends-and-correlations) | todo | minor |
| 17 | [Quick settings tile](#17-quick-settings-tile) | todo | minor |
| 18 | [Automatic backup to a chosen folder](#18-automatic-backup-to-a-chosen-folder) | todo | minor |
| 19 | [Komo grows with you](#19-komo-grows-with-you) | todo | minor |
| 20 | [Material You colors](#20-material-you-colors) | todo | minor |
| 21 | [Wear OS tile](#21-wear-os-tile) | todo | minor |
| 22 | [End-to-end encrypted sync](#22-end-to-end-encrypted-sync) | todo | major, ADR first |

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

**Result (2026-10-30):** the owner's phone found, downloaded, verified and installed 2.3.1 from
2.3.0 through the in-app updater.

**Decisions:** Dart sends both window settings in one `applyWindowProtections` call and
`windowProtectionsFor` in `AppLock.kt` picks the flags, so "Hide from screenshots" turned off
can no longer clear the `FLAG_SECURE` the lock needs below Android 13. The updater follows
redirects itself (`httpsRedirectTarget`) and refuses any that leave HTTPS, for the release
check and the APK download. ADR 0005 got a correction note instead of a new ADR.

## 2b. Update freshness and release notes

Approved on 2026-10-30, before the year in review, so users always know their app is up to date.

- Check for a new version at each launch, at most once an hour (was once a day), still only
  while the automatic check is on. Privacy screen, setting, README and ADR 0002 say so.
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

**Decisions:** "the habit kept longest" is the habit with the most success days in the year
(the longest streak already has its own card). The review covers January 1 to today in December
and the whole year in January. The best month and the most regular weekday compare shares of
successful days, not raw counts, so long months and the weekday that occurs 53 times do not win
by length; ties go to the earliest. Streaks stop at January 1, except a weekly target, which
keeps whole ISO weeks. Below seven success days the review is the short version. The dashboard
card needs at least one log in the year; entry points watch only the year, the full review is
computed when the screen opens (122 ms for 50 habits over ten years). The share image is a new
file per share in `cache/shared_images/` behind a non-exported `FileProvider`, deleted at the
next share or launch; habit names are off by default. Screen notes:
`docs/design/year-in-review.md`.

## 4. Pause and rest days

**Why before quantity habits:** both change how a day counts; streaks must handle a paused day
before a day can also be "half done".

- Pause a habit for a period (holiday, illness): no reminders, no widget entry, and the paused
  days neither break nor extend the streak. Shown on the strip and the yearly grid.
- Optional rest allowance per week (for example one day) that keeps a daily streak alive.
- Schema migration (Drift), backup format version bump with older backups still importing
  (ADR 0001), streak and statistics updates with tests, reminders skip paused days.
- ADR for the counting rules.

**Decisions:** counting rules in `docs/adr/0007-pauses-and-rest-days.md`: a paused day counts
like a day off the schedule (even if logged), an unmet week holding a paused day is neutral,
rest days are 0 to 2 per ISO week capped at the scheduled days minus one and derived from the
logs, not stored. Pauses can be planned ahead; "Resume" ends the pause holding today or cancels
the next planned one; past pauses stay so the history reads the same. A paused day stays
loggable but the log does not count. Paused days are hatched on the strip, the yearly grid and
the day sheet (`docs/design/pauses.md`). Schema v3 and backup format v3; v1 and v2 backups
still import.

## 5. Quantity habits

- A habit can track an amount with a unit and a daily target ("8 glasses", "20 min"): log by
  +1 steps or by typing a value; the day succeeds once the target is reached.
- Schema: a target and unit on the habit, a value on the log. Decide in an ADR whether a
  quantity habit still has objectives or replaces them, and how backups carry it.
- Dashboard button, log sheet, reminders' actions, widget, statistics and achievements all
  learn the new kind.

**Decisions:** `docs/adr/0008-quantity-habits.md`. A habit is either "objectives" or
"quantity"; a quantity habit has a unit, a daily target and a step and keeps one hidden
objective that carries its logs, each with an amount. A day succeeds when its amount reaches the
target, decided on read: the repository's day maps leave out days below the target, so streaks,
recaps, achievements, the year in review, reminders and the widget needed no change. One tap
adds a step (with Undo, even past the target); holding opens a sheet with -/+, a typed amount,
"+5 steps", "Target" and "Clear this day". "Done" on a reminder and a tap on the widget complete
the day (raise the amount to the target, never lower it). The strip and yearly grid shade a day
by its share of the target; statistics show days at the target and the year's total. The kind
cannot change once a habit has a log. Schema v4 and backup format v4; v1 to v3 backups still
import. The widget's snapshot and Kotlin code are unchanged: "logged today" now means "target
reached" for a quantity habit.

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

## 11. Consistency score

- A 0-100 % score per habit: an exponentially weighted share of scheduled days done, so one
  missed day lowers it a little instead of resetting it like a streak. Pauses and rest days
  are ignored. Shown on the details screen next to the streaks, with its trend over 30 days.

## 12. Habit groups

- Optional groups ("Morning", "Evening", "Health") with a name and an order; the home screen
  shows each group under a header that can be collapsed. Habits without a group stay on top.
  Schema and backup change; reorder within and across groups.

## 13. Habits to quit

- A habit kind for things to stop ("No smoking"): the home screen counts the days since the
  last slip and the best run; logging a slip resets it. Achievements and the year in review
  read it the same way as a streak.

## 14. Challenges

- Start a challenge on a habit with an end date ("30 days of reading"): a progress bar on the
  row, a celebration with Komo and a dedicated badge when it ends on time. Abandon at any time.

## 15. Month calendar of all habits

- A month view where each day shows how many scheduled habits were done (a ring or a dot
  scale), with a tap to see and log that day's habits. Swipe between months.

## 16. Trends and correlations

- On-device insights on the statistics screen: best and worst weekdays per habit, and, for
  pairs of habits with enough history, "on days you do A, you do B x % more often". Plain
  sentences, never sent anywhere, hidden below a minimum number of days.

## 17. Quick settings tile

- An Android quick settings tile that logs the first habit planned today and not done yet, or
  opens Komit. Follows the app lock rules: names no habit while locked.

## 18. Automatic backup to a chosen folder

- Pick a folder once with the Android file picker (Drive, Nextcloud, a USB key...); Komit then
  writes an encrypted backup there daily when something changed, keeping the last N. No
  account, no network code in Komit itself.

## 19. Komo grows with you

- Komo slowly gains small, minimal touches (a leaf, a scarf, a crown) as the overall
  consistency score grows, and loses none for a bad week. Stays within the minimal style.

## 20. Material You colors

- An option in Settings to use the wallpaper's colors (Android 12 and later) instead of the
  orange palette; Komo and the icon stay orange.

## 21. Wear OS tile

- A Wear OS tile listing today's habits with a tap to log, talking to the phone over the
  Data Layer. Separate module; ADR on the sync between watch and phone.

## 22. End-to-end encrypted sync

- Keep two phones in sync without a Komit account: an ADR first (transport, conflict rules,
  key exchange by QR code). Large; only after everything above.

## Shipped

Record each finished item here: date, version, pull request or commit, and anything left out.

- 2026-10-30, item 1, no app version: CI workflow and `tool/release.sh`, branch
  `chore/ci-and-scripted-release`. The script's first real run is the 2.3.1 release (item 2).
- 2026-10-30, item 2, v2.3.1: `FLAG_SECURE` for the locked recents card below Android 13 and
  HTTPS-only update redirects, PR #3, released with `tool/release.sh`. In-app update from 2.3.0
  confirmed on the owner's phone; the blank recents card on Android 12 or older was not checked
  on a device.
- 2026-10-30, item 2b, v2.4.0: hourly launch check, rendered release notes, "Welcome to X.Y.Z"
  after an update, up-to-date status in Settings, release notes template, PR #4.
- 2026-10-30, item 3, v2.5.0: year in review (story cards, quiet-year version, share image
  without habit names by default, dashboard card and statistics row), branch
  `feat/year-in-review`. Not checked on a device: TalkBack on the cards, the real share sheet.
- 2026-10-30, item 4, v2.6.0: pauses (planned or open, resume, hatched days) and rest days
  (0 to 2 a week) in streaks, recaps, achievements, reminders, widget, schema v3 and backups
  v3, branch `feat/pause-and-rest-days`. Not checked on a device: TalkBack on hatched cells,
  the real date picker.
- 2026-10-31, item 5, v2.8.0 (not released yet): quantity habits (unit, daily target, step;
  ring button, stepper sheet, shaded grids, statistics total), schema v4 and backups v4, branch
  `feat/quantity-habits`. Not checked on a device: TalkBack on the ring button and the sheet,
  the numeric keyboard, a reminder's "Done" and a widget tap on a quantity habit.
