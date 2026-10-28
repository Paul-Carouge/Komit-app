# Changelog

All notable changes to Komit. Versions follow [SemVer](https://semver.org).

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
