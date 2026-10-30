# Habit editor

The editor creates and edits a habit. Its primary job is to give a habit a name, a rhythm
and something to tick off, then save; appearance and reminders support that. It is opened
from the dashboard ("New habit") and from a habit's page (edit), and must stay calm: the
user is setting up a routine, not playing with a toy.

## Layout

```
Phone (360-412 dp)                         Tablet: the same column, capped at
+------------------------------------+     AppSizes.formMaximumWidth (560 dp), centered
| <                                  |
| New habit            (large title) |
| +--------------------------------+ |
| |          [ ICON 72 ](pencil)   | |   identity card: the card is its own preview
| |  [        Morning run        ] | |   centered fields sunk to the page color
| |  [  Ten minutes count ...    ] | |
| |  (o) (o) (@) (o) (o) (o) ->    | |   color strip, one tap per try
| +--------------------------------+ |
| Schedule                           |
| +--------------------------------+ |
| | [@] Every day             ✓    | |   chosen row: badge in the habit color, check
| |     Seven days a week          | |
| | [#] Some days                  | |
| |     Weekdays                   | |   chosen row's subtitle is the summary
| |  (L)(M)(M)(J)(V)( S)( D)       | |   opens under the chosen row
| | [o] Per week                   | |
| |     ( - )     3      ( + )     | |
| |           days per week        | |
| |--------------------------------| |   rest days: hidden for "Per week"
| | [bed] Rest days                | |
| |  [ None | 1 day | 2 days ]     | |   values the days cannot allow are disabled
| +--------------------------------+ |
| +--------------------------------+ |
| | [bell] Daily reminder    [==]  | |
| +--------------------------------+ |
| Objectives                         |
| What you tick off each day ...     |
| +--------------------------------+ |
| | (o) Walk______________  x  ::  | |   color, name, remove, drag grip
| |     Extends the streak   [==]  | |
| |--------------------------------| |
| |  +  Add objective              | |
| +--------------------------------+ |
+------------------------------------+
| [ ! Each objective needs a name ]  |   frosted save bar: the reason a save failed
| [========  Create habit  ========] |   sits right above the button that revealed it
+------------------------------------+
```

## Tokens

Only existing roles, plus a few sizes added to `AppSizes`:

| Token | Value | Use |
| --- | --- | --- |
| `habitIdentityIcon` | 72 dp | The habit's icon at the top, the largest habit square in the app |
| `editBadge` / `editBadgeIcon` | 28 / 14 dp | The pencil disc telling that the icon can be changed |
| `colorSwatch` | 36 dp | A color in the strip, inside a 48 dp target |
| `formMaximumWidth` | 560 dp | Form column cap on tablets |
| `weekdayToggle` | 40 dp (was 44) | Visible circle of a weekday, inside a 48 dp target |

Color roles: the habit's own color is the editor's accent (icon square, chosen schedule
badge, chosen weekdays), with `foregroundColorReadableOn` for anything drawn on it. The
brand orange stays on the one primary action, the save button. Fields in cards use
`surface` (sunk below the white card in light mode, a darker well in dark mode).
Errors use `errorContainer` / `onErrorContainer`.

Motion: a new icon springs in (`AppCurves.spring`, `emphasized`), the chosen schedule
row's check pops with the same spring, its setting opens with `AnimatedSize` (`standard`
curve and duration), and the weekly number cross-fades with a slight scale. All through
`motionAwareDuration`. Haptics: `selection` for every choice, `lift` when an objective is
picked up, `warning` on removal, `error` on a failed save, `success` on save.

## States

- **Loading**: the shared `DelayedLoadingSkeleton` (nothing for 150 ms, then rows).
- **Load error**: sleepy Komo with "Try again".
- **First run (create)**: one empty objective, every day, default icon and color; the
  objectives help line explains what an objective is.
- **Validation**: the name error sits on the name field, which gets focus (and scrolls
  into view); any other problem shows in the save bar above the button, as a live region.
  "Some days" with no day picked says so live, in the chosen row's subtitle.
- **Saving**: the button shows a spinner and ignores taps.
- **Save failed**: snack bar with the generic error, the form stays as typed.
- **Unsaved changes**: back, the back gesture and the bar's back button ask "Discard your
  changes?" with "Keep editing" / "Discard"; an untouched form leaves at once.
- **Large text (200 %)**: placeholders wrap instead of being cut, the weekday letters
  are clamped to 1.5x so they stay inside their circles, everything else wraps at word
  boundaries. French strings keep non-breaking spaces before "?" and inside guillemets.

- **Rest days**: see [pauses.md](pauses.md). The segmented control takes the habit's color,
  disables values above scheduled days minus one, remembers the choice while weekdays are
  toggled and saves it capped; at 200 % text its labels shrink instead of wrapping.

## Defaults we rejected

- **A three-segment button for the schedule.** "Tous les jours / Certains jours / Par
  semaine" do not fit side by side on a compact phone, and a segment cannot explain
  itself. Three rows in one card can, and the chosen row turns into the summary.
- **"Color" and "Icon" tiles that open sheets.** Two taps and a sheet to try a color;
  the strip makes it one tap with the result in view, and the icon itself is the button.
- **A preview row repeating the fields below it.** The identity card is the preview.
- **A validation message at the end of the list.** It was off screen when the button
  was pressed; it now sits above the button, and the name error on the name field.
- **All seven weekdays ticked when switching to "Some days".** That is "Every day" under
  another name; it starts from Monday to Friday instead.
- **Seven 40 dp weekday targets on narrow phones.** Below about 380 dp the toggles wrap
  to Monday-Thursday / Friday-Sunday, so every target stays 48 dp.
