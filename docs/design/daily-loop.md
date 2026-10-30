# Daily loop: dashboard, logging, editor, archive

The dashboard is where Komit is used every day, often for two seconds. Its primary job is
logging today in one tap; everything else (history, streak, schedule) supports that glance.

## Layout

```
Compact phone (360 dp)                    Large screen: same column, content width capped
+------------------------------------+
|                                (o) |   settings only: Komo left the bar, so the
| Good morning, Paul                 |   collapsed title never slides under it
+------------------------------------+
| (Komo)  3/5 done today       (ring)|   today header, on the page (not a card)
|         Wednesday, October 28      |
| +--------------------------------+ |
| | [ic] Morning run          ( + )| |   round 48 dp log button
| |      [flame 3 days] Logged ... | |   streak chip, then relative words
| | ▢▢▢▢▢▢▢ ▢▢[▣]▫▫▫▫              | |   Mon-Sun last week + this week, today ringed,
| +--------------------------------+ |   future days lighter and inert
| [ + New habit ]                    |
|   Archived (2)                     |   quiet link, only when some exist
+------------------------------------+
```

## Decisions

- **Greeting by time of day** (`GreetingPeriod`, starts at 5, 12 and 18 h). The evening runs
  past midnight: someone logging at 1 a.m. has not started their morning.
- **Today header** counts only habits scheduled today; an off-schedule habit logged anyway
  counts in neither number. The ring uses the brand orange; the "3/5" text carries the
  information, so the ring needs no text contrast. Komo hops when everything is done.
- **One tap logs the first objective** (the user's own "usual" outcome). A tap on a logged
  day, or a long press, opens the sheet. Every write shows a message with "Undo" that
  restores the exact previous state, for `AppDurations.undoSnackBar`.
- **Week-aligned strip.** Fourteen days from last Monday: every row's columns are the same
  weekdays, weekly targets read week by week, and the rest of this week shows as inert
  future days. Days off the schedule use the lighter `futureCell` color: nothing was
  expected. Cells are tall 48 dp slots; screen readers get a named "Log this day" action.
- **Log sheet**: habit header with a relative date, then full-width pills filled with each
  objective's color (text via `foregroundColorReadableOn`); the current choice has a ring
  and a check, not only a fill. Imported future days explain why they can only be cleared.
- **Editor**: see [habit-editor.md](habit-editor.md): an identity card that is its own
  preview, a schedule card whose chosen row opens its setting, grouped objectives, and a
  frosted save bar at the bottom where the thumb is.
- **Reorder and actions**: long press lifts a row (scale `liftedScale`, `AppShadows.lifted`,
  lift haptic). Dragging it reorders; releasing it in place (under `kTouchSlop`) opens the
  same actions sheet as the details screen (edit, archive, delete). "Move up", "Move down"
  and "More actions" are screen reader actions on each card.

## Defaults we rejected

- A greeting card with a motivational quote: filler; the date and the count are the content.
- A floating "+" button for new habits: it would cover the last row's log button.
- Drag handles on every row: visual noise for a rare action; long press plus semantics
  actions cover touch and assistive technology.
- A rolling 14-day strip: columns shifted every day and weekly targets had no week to read.
