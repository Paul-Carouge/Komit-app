# Year in review

From December 1 to January 15, Komo tells the user's year in a short sequence of full-screen
cards, then offers an optional image to share. The primary job is a warm, thirty-second look
back; sharing is secondary and private by default. Data comes from `lib/domain/year_in_review.dart`
(`yearInReviewProvider`), computed on the phone.

## Entry points

- **Dashboard card** (`lib/features/dashboard/year_in_review_card.dart`), between the today header
  and the Monday recap, during the period only. A warm `highlightContainer` card with a resting
  Komo, "Your 2026 in review" and one line. Tapping it opens the review; the cross dismisses it
  for that year (`SettingsRepository.saveDismissedYearInReviewYear`), like the weekly recap. The
  cross sits beside the card in a `Stack`, not inside it, because a `PressableCard` merges its
  content into one tappable node that would swallow a second action.
- **Statistics row**, at the end of a habit's statistics, during the period only: the way back
  once the dashboard card is dismissed.
- **Route** `/year-in-review`, a full-screen dialog (rises from the bottom, closes with a cross).
  Outside the period it shows a sleepy Komo saying when the review opens.

## Layout

```
Compact phone (360 x 640)               Tall phone: Komo grows to mascotLarge
+------------------------------------+
| (x)                   ● ● ▬▬ ○ ○ ○ |  close at the start; progress as day cells
|              (Komo)                |  fixed: the cards slide under it, its mood follows the card
|        /\                          |
|  ( Your longest streak: )          |  Komo's line, a warm bubble whose tail points at Komo
|                                    |  one third of the free height
|               21                   |  hero value: displayLarge, w800, accentText, counts up
|          days in a row             |  titleLarge
|       [ic] Morning run             |  optional picture (habit, cells, achievement chips)
|                                    |  two thirds of the free height
| <      [        Next  ->        ]  |  back (hidden on the first card), one filled action
+------------------------------------+
```

Each card scrolls on its own when large text or a short screen needs it. Below 700 dp of height
with text at 150 % or more, Komo shrinks to `mascotSmall` so the words keep the room. Content is
capped at `readableContentMaximumWidth` on tablets.

## Cards

| Card | Komo | Content | Skipped when |
| --- | --- | --- | --- |
| Intro | waving | the year, "Your year with Komit", "January 1 to {last day}" | never |
| Success days | happy | count of days with at least one success | never in a full year |
| Longest streak | happy | length, days or weeks in a row, the habit | `longestStreak` is null |
| Most regular day | idle | weekday name, a strip of 7 cells with that day filled | null |
| Best month | idle | month name, a strip of 12 cells with that month filled | null |
| Habit kept best | happy | habit badge (72 dp), name, its success days | null |
| Achievements | happy | count and one chip per achievement (family color, Lucide icon) | none unlocked |
| Outro | waving | "Thank you… see you in {next year}?", share preview, names toggle, share button | never |

**Quiet year** (`isQuietYear`, fewer than 7 success days): intro, one kind card ("A calm year,
and that's fine." with the exact count in a sentence, never a big number), and an outro without
sharing ("{next year} is a blank page. I'll be right here."). **No success at all**: the middle
card says "Your story starts here" and that one day is enough to begin.

## Share image

- Rendered on the phone from the preview on the outro card (`RepaintBoundary` → PNG at
  pixel ratio 3, 1080 × 1920). What the user sees is exactly what is shared.
- **No habit names by default.** The switch "Show habit names" adds them to the streak and
  habit lines; its subtitle states the consequence in both positions, and the preview's screen
  reader label says "with" or "without habit names".
- Always the light theme, at a fixed size and a fixed text scale: the image lives in other apps on
  unknown backgrounds and must look the same whoever shares it. Komo is in its resting pose.
- A failure (no receiving app, encoding error) is logged and shown with `showMessageSnackBar`:
  "The image couldn't be shared. Try again."
- Hidden where the platform has no share channel (`ImageShareService.isSupported`).

## Motion

- One expressive moment per card: the hero number counts up (`AnimatedCount`), and Komo answers
  the mood change with one short gesture (`mascotHeaderAnimationBudget`).
- Cards slide over `AppDurations.storyCard` (360 ms, `AppCurves.standard`); the progress cell
  stretches with `AppCurves.emphasized`.
- Reduced motion: cards jump, numbers appear at their value, Komo stays still.
- Haptics: `selection` on each card change and on the names switch, `error` on a failed share.

## Accessibility

- Each content card is one live region read in one go ("Your longest streak: 21 days in a row,
  Morning run"). The outro is not merged, so its switch and button stay separate controls.
- A tap anywhere on a card moves on (story convention) but is hidden from screen readers; the
  "Previous card" and "Next" buttons do the same job for TalkBack, Switch Access and keyboards.
- The cell strips are excluded from semantics: the winning day or month is already written above
  them, so they never carry the answer by color alone.
- Progress is read as "Card 3 of 8". All controls are at least 48 dp. Tested at 200 % text on a
  360 × 640 phone in English and French, and against the tap target, label and contrast guidelines.

## Copy decisions

- Komo speaks in the first person and asks, the cards answer: "Your most regular day:" then
  "Tuesday". French says "tu", with non-breaking spaces before `?` and `:`.
- "Success days", not "logged days": a skipped day logged is not a success.
- French calls achievements "succès", like the rest of the app (invariable plural).
- Weekday and month names are capitalized because they stand alone as titles.

## Defaults we rejected

- **A "Wrapped" look** (neon gradients, a new color per card, big sans display type): off-brand
  and loud. The cards stay on the page color; color comes from Komo, the accent orange of the
  numbers and the user's own habit and achievement colors.
- **Komo inside each card**: it would leave and arrive with every swipe. It stays fixed and
  narrates, which is the point of the feature.
- **Auto-advancing timed stories**: they rush slow readers and screen reader users. The user sets
  the pace.
- **A tonal back button**: the theme's tonal color is the violet secondary, off-brand next to
  the orange action; a plain icon button is quieter and matches the onboarding.
- **A filled share button**: sharing is optional; "Done" stays the single filled action.
- **Names in the image by default**: Komit is private; showing what someone tracks is the user's
  explicit choice.
