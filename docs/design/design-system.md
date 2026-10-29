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

- A violet gradient banner on the notes tab: decorative and off-brand; it is now the warm
  `primaryContainer` tint.
- Scaling one title widget between expanded and collapsed (Flutter's `FlexibleSpaceBar`):
  it slides under the actions and cannot wrap; two titles (large, then toolbar) are iOS's
  approach and avoid both.
- A centered spinner for loading: replaced by delayed row-shaped placeholders.
- Shadows in dark mode: invisible on near-black and costly; lighter surfaces replace them.
- An orange window background: it flashed between the splash and the first screen.
