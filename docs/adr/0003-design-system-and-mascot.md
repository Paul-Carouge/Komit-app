# 3. Design system, Komo the mascot, and brand assets

Date: 2026-10-28 · Status: superseded by [0006](0006-material-3-expressive-art-direction.md) for the visual style (palette, type, shapes, Komo's look); the token structure and the haptics decisions still hold

## Context

Komit's look was already warm (cream paper, amber, a violet notes gradient) but stayed
close to Material defaults: system font everywhere, a few hard-coded sizes, opacities and
colors in screens, no motion vocabulary, the default Flutter launcher icon, a blank white
splash and an onboarding that was a single form. The user wants a coherent and distinctive
art direction, a mascot named Komo, haptic feedback and a better first run.

The product's signature is the day grid: every logged day is a small colored square.
The design system grows from that.

## Decision

### Concept: "the paper habit tracker that comes alive"

- **Palette.** Kept: cream `#FBF6E5` surface, amber `#F9A825` primary, violet notes
  gradient. Changed: near-black text becomes a warm ink `#231A10`, so text and Komo's face
  belong to the same family as the paper. Dark theme keeps the warm night surface `#16140F`.
  Amber is too light on cream for text, focus rings or labels (WCAG 1.4.3 / 1.4.11), so
  `KomitColors.accentText` (deep amber `#8A5300` by day, brand amber at night) carries every
  amber text, focused field border, floating label and cursor.
- **Typography.** Fraunces (SIL OFL 1.1, bundled as one 360 KB variable font) sets display,
  headline and `titleLarge` styles: greetings, screen and sheet titles, big numbers. The
  `SOFT` axis is at its maximum so the serifs are rounded like Komo; weight and optical size
  are set as variation axes, with a nominal normal weight so the engine never adds a fake
  bold. Body text and labels stay on the platform sans for legibility.
- **Shape.** One radius scale by role (`AppRadii`): grid cell 4, small 8, badge 12, control 16,
  tile 20, card and sheet 28. Komo, the step indicator and the celebration sparkles reuse the
  day-cell shape.
- **Elevation.** Flat by default (`AppElevation.flat`); depth comes from surface container
  tones. Only floating elements (snack bars) get `AppElevation.floating`.
- **Opacity.** `AppOpacity` names every tint (badge tints, selected tint, overlay on color).
- **Motion.** `AppDurations` (quick 120 ms for presses, standard 240 ms for in-screen
  changes, emphasized 460 ms for a logged day, plus Komo's cycles) and `AppCurves`
  (`easeOutCubic`, `easeOutBack` for things the user just created). Motion answers an action:
  cards sink to 97 % while pressed (`PressableCard`), a freshly logged day pops into its cell
  with a fading ring, onboarding steps fade and rise. Page transitions are the Android
  predictive-back transition with a cream fallback scrim; `enableOnBackInvokedCallback` is on
  so Android 14+ shows the back preview. `motionAwareDuration` returns zero when the system
  asks to remove animations.

### Komo

- An amber day tile with a sprout on top, two eyes, cheeks and a smile, drawn by a
  `CustomPainter` in a 100-unit design box (`KomoGeometry`); no bitmap asset.
- Moods (`KomoMood`): `idle` (breathing, blinking), `happy` (hop, raised arms, sparkles
  shaped like day cells), `sleepy` (eyes closed, drooping sprout, rising "z"), `waving`.
  Poses are pure periodic functions of the cycle progress (`KomoPose.of`), so progress 0 and 1
  are the same resting pose and the animation can stop on any cycle boundary.
- API for other features: `KomoMascot(mood: KomoMood.happy, size: AppSizes.mascotSmall)` and
  `KomoEmptyState(mood:, title:, message:, action:)`.
- Battery: one `AnimationController` repaints only the mascot's `RepaintBoundary`, and the
  animation stops after `AppDurations.mascotAnimationBudget` (12 s); tapping Komo replays it.
  With animations disabled in the system, Komo is drawn at rest and never ticks.
- Komo is decorative for screen readers unless given a `semanticLabel`.
- Where it appears: onboarding (waving, idle, sleepy, then happy on finish), the dashboard
  header (happy once every habit is logged today, idle otherwise), and empty or error states
  (no habit yet, no notes, nothing logged this year, habit not found, loading error).

### Haptics

`KomitHaptics` maps meanings to platform feedback: `selection` (a choice moved), `success`
(a day logged, something saved), `celebration` (finishing onboarding), `warning` (something
removed or cleared), `error` (an action failed). Android routes these through the view's
haptic feedback, which honors the user's system "touch vibration" setting.

### Onboarding

Three steps led by Komo, with a progress indicator drawn as day cells:
1. Hello, with "Restore from a backup" for returning users.
2. First name, optional ("Skip").
3. Reminders: explains the evening notification before Android asks for the permission;
   "Not now" finishes without asking.
Komo stays mounted across steps so its mood changes without a cut. The layout scrolls with
large text, a keyboard or in landscape, and actions stay low, near the thumb.

### Brand assets on Android

- Adaptive launcher icon: cream background, Komo foreground (same geometry as the painter,
  scaled into the 66 dp safe zone), and a monochrome layer for Android 13+ themed icons.
- Legacy PNG icons for Android 7 are rendered from `docs/design/komit-launcher-icon.svg`.
- Splash: Android 12+ system splash with Komo on the brand background (cream, warm night in
  dark mode); earlier versions use a layer-list with the same drawable. The window background
  behind Flutter uses the same color to avoid a white or black flash.
- Notification small icon `ic_stat_komo`: Komo's silhouette, kept from resource shrinking by
  `res/raw/keep.xml` because only Dart names it. The full-color launcher icon would render as
  a blank square in the status bar.

## Alternatives rejected

- **Material's default purple or a dynamic (wallpaper) color scheme**: would erase the warm
  paper identity users recognize.
- **A rounded geometric sans (Nunito, Fredoka) for headings**: the default choice for a
  friendly app; Fraunces gives a journal voice that fits a habit diary and pairs with cream.
- **Lottie or Rive for Komo**: a new dependency and asset pipeline for four simple moods;
  a painter is lighter, themeable in light and dark, and shares its geometry with the icon.
- **A mascot that loops forever**: keeps the GPU awake on the main screen; a budget plus
  tap-to-replay keeps the delight without the battery cost.

## Consequences

- New user-facing text must use theme text styles; new sizes, radii, opacities and
  durations go through `AppSizes`, `AppRadii`, `AppOpacity`, `AppDurations`, `AppCurves`.
- Changing Komo's geometry means updating `KomoGeometry`, the three Android vector drawables
  and the SVG master, then re-rendering the legacy PNGs.
- The APK grows by about 360 KB for the font.
