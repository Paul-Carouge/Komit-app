# Changelog

All notable changes to Komit. Versions follow [SemVer](https://semver.org).

## [Unreleased]

### Added
- Meet Komo, Komit's mascot: it waves during the first launch, celebrates on the home
  screen once every habit is logged today, and keeps you company on empty screens.
  Tap it to play its animation again.
- A new three-step welcome: say hello (or restore a backup), choose your first name,
  then decide about reminders, with an explanation before Android asks for permission.
- A new app icon featuring Komo, with a themed (monochrome) version on Android 13 and
  later, a matching splash screen, and Komo in the notification bar.
- Haptic feedback: a light tap when you log a day or save, a firmer one when you remove
  something, a double tap when you finish the welcome. It follows your phone's vibration
  setting.
- A freshly logged day pops into its square; cards gently sink when you press them.

### Changed
- Headings use a new rounded serif typeface, and text colors are slightly warmer.
- Focused text fields, their labels and the cursor use a darker amber that is easier to see.
- Messages appear in a floating bar at the bottom of the screen.
- Screen transitions follow Android's back gesture preview on Android 14 and later.
- When animations are turned off in the system settings, Komit stops animating too.

## [2.0.0] - 2026-10-28

Complete rewrite of Komit.

### Added
- Import of backups exported by the original Komit app: every habit, objective and
  logged day is kept, including logs of objectives deleted in the old app.
- In-app updates: Komit checks for new versions and installs them after verifying
  the download, with the list of changes.
- Export now saves the backup to a file of your choice on the phone.
- Tap any past day in the yearly grid to log it, change it or clear it.
- Change your first name from Settings.
- Dashboard cards show the last 28 days of each habit.

### Changed
- New storage engine (SQLite): faster, transactional, and a log stays attached to its
  objective even when you rename it.
- "Total completions" becomes "Days logged", with the share of each objective.
- Reminders no longer need the exact-alarm permission.
- Better contrast and screen-reader support across the app.

### Fixed
- Days in the future can no longer be logged by mistake.
- Imports are all-or-nothing: a broken file never leaves half-imported data.
