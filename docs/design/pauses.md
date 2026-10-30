# Pauses and rest days

A pause puts a habit on hold for a holiday or an illness; rest days let a daily or weekday
habit skip one or two days a week. Counting rules: [ADR 0007](../adr/0007-pauses-and-rest-days.md).
The primary job of every surface here is to reassure: the streak is safe, nothing is asked.

## The one mark: hatched days

A paused day is drawn as a day off the schedule (`futureCell`) with thin diagonal stripes in
`KomitColors.pausedCellStripe` (`AppSizes.pausedHatchStrokeWidth` 1.5 dp, every
`pausedHatchSpacing` 4 dp), painted by `paintPausedHatch` in `day_grid.dart`. The texture, not a
color, says "on hold", so it reads in both themes and for color-blind users. The same cell is
shown as a 20 dp `PausedDaySwatch` next to every pause's dates (pause sheet, habit page, log
sheet), so the grids need no legend. A paused day that was logged anyway keeps its plain
objective color (the log is a fact) and its label says it does not count.

Screen readers hear "Wednesday, October 28: paused", or "...: Walk, paused, does not count".

## Flows

```
Actions sheet (dashboard long press, details "...")     Pause sheet (compact phone, 360 x 640)
+------------------------------------+                  +------------------------------------+
| [pencil] Edit habit                |                  | [icon] Pause Morning run           |
| [pause]  Pause                     |  no pause        | Paused days neither break nor ...  |
|   or                               |                  | Starts                             |
| [play]   Resume                    |  current pause   | (v Today) (Tomorrow) ([cal] Pick)  |
|          Paused until Nov 12       |                  | Ends                               |
| [play]   Cancel the planned pause  |  planned pause   | (v Until I resume) (1 week)        |
|          Pause starts Nov 3        |                  | (2 weeks) ([cal] Pick a day)       |
| [archive] Archive habit            |                  |- - - - - - - - - - - (scrolls above)
| [trash]  Delete habit              |                  | [///] Oct 28 to Nov 3 · 7 days     |
+------------------------------------+                  | [=========  Pause habit  =========]|
                                                        +------------------------------------+
```

- **Pause** opens the sheet. Start: today by default, tomorrow, or a picked day (up to a year
  ahead). End: until resumed by default, one or two weeks (seven or fourteen days, included),
  or a picked day. The summary under the choices states the exact range and day count, so the
  quick picks are never ambiguous. The summary and the button stay fixed under the scrolling
  choices: on a compact phone the action never falls below the fold.
- **Saved**: "Morning run is paused" (or "Morning run pauses from Oct 29") with "Undo", which
  is exact because "Pause" is only offered when no pause is current or planned.
- **Rejected** (`InvalidPauseException`, an overlap written meanwhile): "This habit is already
  paused on some of these days. Pick other dates." Any other failure: the generic error.
- **Resume** ends the current pause on yesterday; for a planned pause the action is "Cancel the
  planned pause" and cancels the earliest one. No "Undo": a pause that started before today
  cannot be written again. Message: "Morning run counts again from today".
- Archived habits offer no pause: they have no row and no reminder.

## Dashboard row

A habit paused today shows "Paused until Nov 12" (or "Paused" when open-ended) where an
off-schedule habit says "Not today"; the header counts it in neither number. It **stays
loggable**: the ADR lets a success be logged on a paused day, it just does not count. The log
button takes the same outline as an off-schedule day (available, not expected), and the log
sheet says "Paused that day: a log here does not count toward the streak." A planned pause
already hatches the rest of this week on the strip. The weekly progress ("2/3 this week")
ignores successes on paused days.

## Habit page

A `SoftCard` under the hero card while a pause is current or planned: the swatch, "Paused until
Nov 12" / "Paused until you resume" / "Pause starts Nov 3", "Your streak waits for you.", and a
text button "Resume" (or "Cancel the planned pause"): people come to the page to check on a
paused habit, so the way out is not hidden in the menu. Under the streak cards, a muted line
with a bed icon when rest days are set: "1 rest day a week keeps your streak alive".

## Rest days in the editor

The last section of the schedule card, under a hairline: bed badge, "Rest days", "Missed days
each week that keep your streak alive", then a segmented control None / 1 day / 2 days in the
habit's color. It collapses (`AnimatedSize`) for a weekly target, which already lets people pick
their days. Values above `maximumRestDaysFor(mask)` (scheduled days minus one) are disabled,
not hidden, so the control keeps its shape while weekdays are toggled; the chosen value is
remembered and only capped when shown and saved. At 200 % text the labels shrink to fit
instead of breaking mid-word.

## Defaults we rejected

- **A dimmed or desaturated cell for paused days.** It looked like a missed day at a glance and
  relied on a shade alone; stripes are a texture that survives both themes.
- **A switch "Paused" in the editor.** A pause has dates; a switch hides the end and invites
  forgetting to turn it off. Pausing is an action with its own sheet, next to archive.
- **Calendar range picker as the first step.** Most pauses are "from today, until I'm back" or
  a week or two; chips make those one tap, the picker stays for the rest.
- **Hiding the log button on a paused day.** The ADR allows the log; hiding it would make the
  row look broken and lose a real success.
- **A pause icon in the log button.** It reads as "pause this habit", not "log today".
