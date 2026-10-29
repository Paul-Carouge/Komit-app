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
- Backups also save each habit's schedule, weekly target and archive state, and which
  outcomes count as a success. Older backups still import, with every habit kept daily.
- Komit keeps a small error log on the phone only, to help fix crashes. It never contains
  your habit names, notes or first name, and it never leaves the device.
- A freshly logged day pops into its square; cards gently sink when you press them.
- A livelier start: on the splash screen Komo blinks once, then its face fades away to
  reveal the app instead of cutting to it. With animations turned off, the app appears
  at once.
- One tap on the round button of a habit logs today with its first objective. Every log
  shows a message with "Undo"; a long press, or a tap on a day already logged, lets you
  choose another objective or clear the day.
- Tap any day of the two-week strip on the home screen to log it. Today is ringed, and the
  rest of the week stays unavailable until it comes.
- The home screen greets you by the time of day and shows how many of today's habits are
  done, with a ring that fills up; Komo celebrates there once everything is done.
- Each habit shows its current streak, when it was last logged ("Logged yesterday"),
  "Not today" on days off its schedule, and "2/3 this week" for weekly targets.
- Choose a schedule when you create or edit a habit: every day, some days of the week, or a
  number of days per week. Outcomes such as "Skipped" can be set to not extend the streak.
- The habit editor previews the habit as it will appear on the home screen and has a large
  save button at the bottom.
- Archive a habit from its page to take it off the home screen without losing its history.
  Archived habits are listed under "Archived" at the end of the home screen, from where they
  can come back.
- Long-press a habit on the home screen to move it. Screen readers offer "Move up" and
  "Move down".
- Reminders have buttons: log the day with "Done" (or one of the first two objectives), or
  "Later" to be reminded again in an hour. Tapping a reminder opens its habit.
- Reminders show your current streak, and skip days off the habit's schedule, days already
  logged and archived habits.
- Settings show whether notifications are on, with a shortcut to the system settings.
- Settings have an "About" section with the version, the open-source licenses and a link to
  every Komit version on GitHub.
- The language can follow the phone ("System"), and Android 13 and later list Komit in the
  per-app language settings.
- Before Komit asks to install apps for an update, it explains why; once you allow it and
  come back, the update continues on its own.
- Milestones are celebrated: the first day of a habit, streaks of 3, 7, 14, 30 days and
  more, and each new achievement show a short card at the top of the screen with Komo and a
  burst in the habit's color. Each one plays only once, the card never blocks the screen,
  and it appears without motion when animations are turned off.
- Achievements: five long-term goals (first week, perfect week, 100 days, comeback, one
  year), opened from the trophy on the home screen. They are worked out from your logs, so
  they always match your history.
- On Mondays, the home screen recaps last week: success days per habit against its
  schedule, the longest streak and the change from the week before. Dismiss it with the
  close button; it stays hidden for that week.
- The habit icon now travels from the home screen to the habit page, and the first habits
  and notes rise gently into place when a list opens. Streaks and totals count up.
- Monthly statistics use the habit's color, highlight the current month, and show the
  month and count when you touch a bar.
- Long-press Komit's icon for two shortcuts: "New habit" opens the habit editor and
  "Today" opens today's habits.
- A "Today" widget for the home screen lists the habits planned today. Tap a habit's
  round button to log it with its first objective, without opening the app; tap the
  title to open Komit. It follows dark mode and, on Android 12 and later, your wallpaper
  colors. It never appears on the lock screen and holds only habit names and colors.
- Backups of your phone to Google's cloud no longer include Komit's data, which stays on the
  phone. Moving to a new phone with a cable or Wi-Fi transfer still copies everything.
- Turn off "Check for updates automatically" in Settings. When it is on, Komit asks GitHub
  at most once a day instead of at every launch.
- Automatic backups: before every import, before an update is installed, and once a day
  when something changed, Komit keeps a copy of your data on the phone. The 10 most recent
  copies can be restored from Settings → Data & storage → "Restore an automatic backup".
- Settings reminds you to export your data when the last export is more than 30 days old.
- Export with a passphrase: Settings → Data & storage can now save an encrypted file that
  only opens with the passphrase you choose. Importing such a file asks for it. Plain
  exports stay the default, since a forgotten passphrase cannot be recovered.
- Lock Komit (Settings → Privacy & security): Komit then asks for your fingerprint, face or
  screen lock when it opens and after a minute away, with a sleepy Komo guarding the
  screen. Recent apps shows a blank card for Komit on Android 13 and later. The option is
  greyed out, with an explanation, until the phone has a screen lock.
  While it is on, the "Today" widget and reminders no longer name your habits or log them:
  they only open Komit, which asks to unlock.
- "Hide from screenshots" blocks screenshots and screen recordings of Komit.
- A "Your privacy" screen explains what stays on your phone, what leaves it (only the
  update check), how backups and exports work, and why Komit needs each permission. Open it
  from Settings → Privacy & security or from the last welcome step.

### Changed
- A smaller download: the app is 3 MB lighter (25.6 MB to 22.6 MB), since it now only
  carries the icons it shows, the native code for 64-bit phones and no debug symbols.
- A cleaner start: Komo's face stays until your habits are loaded (at most 0.8 s), so it
  fades straight onto them instead of onto a loading screen.
- Screens slide in and out again, with Android's back gesture preview: an update of the
  navigation library had silently turned every screen transition off.
- Komo next to the home screen greeting no longer moves on its own; it hops when the last
  habit of the day is logged, or when you tap it.
- Komit now draws behind transparent status and navigation bars on every Android
  version, and the screen behind the app has the page color, so there is no orange flash
  after the splash screen.
- Importing a backup made by this version now refuses a file with a day logged in the
  future, or with a description or note longer than the app allows. Backups from the
  original Komit app still import in full.
- Habit descriptions are limited to 1,000 characters and notes to 20,000.
- The database now uses a safer journal mode, ready for logging from notifications and
  widgets. Your existing habits, logs and notes are kept as they are.
- Headings use a new rounded serif typeface, and text colors are slightly warmer.
- Focused text fields, their labels and the cursor use a darker amber that is easier to see.
- Messages appear in a floating bar at the bottom of the screen.
- Screen transitions follow Android's back gesture preview on Android 14 and later.
- When animations are turned off in the system settings, Komit stops animating too.
- Settings and statistics open with a large title that shrinks into the top bar as you
  scroll; a habit's name slides into its top bar once you scroll past its card.
- Cards have a softer shadow in light mode; in dark mode they stand out with a lighter
  surface instead. The notes banner uses the warm Komit tint instead of a violet gradient.
- While a screen loads, placeholder rows appear after a short moment instead of a spinner.
  If loading fails, the screen explains it and offers a "Try again" button.
- Komit asks for notifications only when you turn on a habit's reminder, after explaining
  what that reminder will do. If you refuse, the switch turns back off and offers the system
  settings. The welcome screens no longer show Android's permission dialog.
- Reminders are planned a week ahead and rebuilt after each log, when you open the app,
  after a restart and when the time zone changes. A reminder already on screen is no longer
  removed when Komit updates the others.
- On the lock screen, a reminder shows only "Komit", never the habit's name.
- Importing a backup is no longer shown in red in the settings; it still asks for
  confirmation before replacing your data.
- If notifications cannot be set up on the phone, Komit still opens normally.
- Exporting a long history no longer freezes the screen: the export row shows a spinner
  while the file is prepared.

### Fixed
- A new note saved with the check button and closed at the same moment is no longer stored
  twice. Notes are also saved when Komit goes to the background, and a failed save says so.
- The habit editor shows an error with "Try again" instead of loading forever when the habit
  cannot be read.
- When you scroll the home screen, the greeting no longer slides under Komo and the
  settings button: it shrinks into the top bar and stops before them, even with a long
  first name or a large font.
- Bottom sheets (logging a day, picking a year, a color or an icon) now cover the bottom
  navigation bar instead of opening behind it.
- With a very large font, section headings, the statistics summary, the "New habit" button
  and the color and icon choices no longer get cut off.
- The language choice and other unselected options have more readable text.
- A screen left open overnight now always moves to the new day at midnight, even when
  the phone wakes its timer a moment early.
- When an update cannot be installed (cancelled, not enough storage, incompatible, blocked
  or conflicting with another version), Komit now says why, and the downloaded file is
  removed after a failed download.
- An import whose data was saved no longer reports a failure when only the first name in
  the file could not be saved.
- Restoring an automatic backup or one of your exports no longer fails when it holds a day
  logged in advance in the original app, and a failed restore now says why.
- Backups from the original app import even with a very long note or habit description.

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
