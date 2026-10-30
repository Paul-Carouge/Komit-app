# Komit design system

Komit is a private, offline habit tracker. Its look is Material 3 Expressive, smooth and
clean, with premium touches borrowed from iOS and kept native to Android: frosted bars,
large titles that collapse, spring motion, soft diffuse depth and haptics. The code source
of truth is `lib/core/theme/app_theme.dart` and `lib/core/theme/app_motion.dart`; this page
records why the tokens are what they are.

## Palette and roles

| Token | Light | Dark | Role |
| --- | --- | --- | --- |
| `primary` (brand orange) | `#FF8C1A` | `#FF9D42` | Komo, selected states, primary fills |
| `accentText` | `#AD4E00` | `#FF9D42` | Orange text and focus rings (4.5:1 on cards) |
| `surface` | `#F6F4F1` | `#0F0E0D` | Page; also the Android window background |
| `surfaceContainerLow` | `#FFFFFF` | `#1F1D1B` | Cards |
| `surfaceContainerHigh` | `#EAE6E1` | `#2C2A28` | Controls on cards; sheets and dialogs in dark |
| `primaryContainer` | `#FFE7D1` | `#4D2A08` | Warm highlights: streak, notes banner, nav indicator |

Depth: light mode lifts cards with one large, faint, offset shadow (`AppShadows.card`:
blur 32, spread -8, offset 12, no tight contact shadow, so no gray ledge). Dark mode has no
shadows: page, cards and sheets step up through `surface`, `surfaceContainerLow` and
`surfaceContainerHigh`.

## Type

Roboto with Material 3 Expressive emphasis (heavy, slightly tightened headlines). Large
titles use `headlineLarge`; collapsed bars use `titleLarge`. App bars clamp the user's font
scale to `AppTextScaling.appBarMaximumScaleFactor` (1.5), because titles already start
large and bars have a fixed height; body text keeps the full scale, tested at 200 %.

## Shape, spacing and sizes

Radii from `AppRadii.gridCell` (5) to `AppRadii.large` (32): nothing a finger touches has a
sharp corner. Spacing follows `AppSpacing` (4, 8, 12, 16, 24, 32, 48) with a 20 dp screen
gutter. Touch targets are at least 48 dp; app bars are `AppSizes.topAppBarHeight` (64 dp)
and keep `AppSpacing.appBarActionsEndInset` (8 dp) after their last action.

## Motion

Durations live in `AppDurations`: `quick` (120 ms) for presses, `standard` (240 ms) for state
changes and cross-fades, `emphasized` (460 ms) for a freshly logged day. Loading shows
nothing for `loadingSkeletonDelay` (150 ms), then placeholder rows. Every animation goes
through `motionAwareDuration`, which removes it when the system asks for reduced motion.

One expressive moment per surface:
- **Hero**: the habit icon flies from its home row to the habit page (`HabitIconHero`),
  lerping size, corner radius and colors. `HeroMode` turns it off under reduced motion.
- **Entrance**: `ListEntranceChoreographer` staggers the first `maximumStaggeredEntranceCount`
  (8) rows of the first build by `entranceStaggerStep` (40 ms), each fading and rising
  `entranceRiseDistance` (8 dp) over `entrance` (360 ms). Rows inserted later open room for
  themselves; scrolled-in rows, moves and rebuilds never animate. Removal is not animated.
- **Counters**: `AnimatedCount` counts up over `counter` (720 ms) in tabular figures; screen
  readers hear only the final value.
- **Celebrations**: a card drops in at the top (never modal, so "Undo" stays reachable),
  with Komo hopping and a hand-painted burst of rays in the habit color over
  `celebrationBurst`, for `celebrationVisible` (4 s). Reduced motion shows the same card,
  static, without the burst. Each celebration id is stored, so it plays once ever.
- **Komo in headers** moves only on a mood change or a tap, for
  `mascotHeaderAnimationBudget` (2.5 s): it sits next to text and must not pull the eye.

Achievements each have their own Lucide icon in a `HabitIconBadge`, tinted by family
(`AchievementFamilyColors`: beginnings green, streaks orange, perfection yellow, totals
blue, variety teal, special days pink, comebacks violet; mapping in
`lib/features/achievements/achievement_appearance.dart`). Unlocked tiles are `SoftCard`s;
locked ones are outlined, with the icon in `mutedText`. The status is also written, so it
never relies on color alone.

## Komo

Komo is the launcher icon come alive: an orange rounded square (76 units, radius 26, on a
108-unit grid) with two pill eyes (11 x 20, ±12.5 from the center, 33 units below the top),
drawn by `KomoPainter`. It has no mouth, arms or outline; it shows moods only through motion
and its eyes (`KomoMood`: idle breathes and blinks, happy hops and squints, sleepy closes its
eyes, waving tilts and glances). Never add detail to it.

Holidays (French calendar, `lib/domain/seasons.dart`): a witch hat (October 24 to
November 6), a Santa hat (December 1 to January 6) and bunny ears (Palm Sunday to the
Sunday after Easter). Accessories are flat shapes in `SeasonalAccessoryColors`, drawn in
Komo's own coordinates so they move with it; Komo shrinks to 80 % to make room.
`KomoSeasonScope` passes the season down from `currentSeasonProvider`, so every Komo dresses
up and goes back to normal on its own.

## Icons, colors of habits, haptics

- Icons: Lucide only, through `KomitIcons` (one vendored font, tree-shaken). Add a glyph by
  its code point from `assets/fonts/lucide_codepoints.json`; never mix icon families.
- Habit colors come from `habitColorPaletteArgb` (20 colors). A habit's color tints its
  icon badge, grid cells, schedule controls and celebration burst; brand orange stays for
  primary actions and Komo.
- Haptics through `KomitHaptics` only: `selection` for choices, `success` for a log or save,
  `warning` before a destructive action, `celebration` for milestones.

## Voice

French copy always says "tu", in Komo's warm, short voice; English is plain and friendly.
Sentences are short, actions are verbs ("Noter aujourd'hui"), errors say what happened and
what to do. French uses non-breaking spaces before `?`, `!`, `:` and inside « ».

## Layout patterns

```
Root tab (dashboard, notes)        Pushed screen (settings, stats)    Habit details
+------------------------------+  +------------------------------+  +------------------------------+
|                    (Komo) (o)|  | <                            |  | <  Morning run  [2026 v] |l ...|
| Hello, Paul!                 |  | Settings                     |  +------------------------------+
| (large title, 2 lines max)   |  +------------------------------+  | [hero card: icon + title]    |
+------------------------------+  | section, cards...            |  | streaks                      |
| habit rows ...               |  |                              |  | yearly grid ...              |
+------------------------------+  |                              |  |                              |
| [frosted navigation bar]     |  |                              |  |                              |
+------------------------------+  +------------------------------+  +------------------------------+
Collapsed: | Hello, Pa… (Komo) (o) |   the title is the toolbar title, laid out between the
back button and the actions, so it can never pass under them.
```

`LargeTitleSliverAppBar` draws the large title under the toolbar; it slides under the
toolbar edge and fades out as the content scrolls, then the toolbar title fades in. The
expanded bar grows to fit a two-line title. Details uses a pinned frosted bar whose title
fades in once the hero card is scrolled away. Every modal sheet opens on the root
navigator, so it covers the frosted navigation bar.

## Native shell and splash

Edge-to-edge on every Android version (`SystemUiMode.edgeToEdge`), with transparent system
bars whose icons follow the theme (`systemUiOverlayStyleFor`). The window behind Flutter is
the page color in day and night, so nothing flashes orange after the splash.

Splash: the orange launcher icon grows into Komo's face (orange screen, two pill eyes),
which blinks once (`splash_komo_blink.xml`, 800 ms, matching
`windowSplashScreenAnimationDuration`). Before Android 12 the same face is drawn at the same
288 dp size. Flutter's first frame repeats the face, then fades it away over
`AppDurations.splashHandoff` (420 ms) while the eyes grow slightly; it is skipped when the
system reduces motion. The launcher icon itself is unchanged.

## Defaults we rejected

- A game look (thick outlines, chunky 3D buttons, Supercell style): rejected by the user as
  not pretty and too far from the original app.
- A display serif (Fraunces) for headings: rejected; Roboto with heavy headlines instead.
- A detailed Komo or launcher icon (limbs, mouth, highlights): rejected; the icon is only
  orange with two pill eyes.
- A grid of habit tiles on the home screen: replaced by a list, which shows the two-week
  strip and the one-tap button side by side.

- A violet gradient banner on the notes tab: decorative and off-brand; it is now the warm
  `primaryContainer` tint.
- Scaling one title widget between expanded and collapsed (Flutter's `FlexibleSpaceBar`):
  it slides under the actions and cannot wrap; two titles (large, then toolbar) are iOS's
  approach and avoid both.
- A centered spinner for loading: replaced by delayed row-shaped placeholders.
- Shadows in dark mode: invisible on near-black and costly; lighter surfaces replace them.
- An orange window background: it flashed between the splash and the first screen.
