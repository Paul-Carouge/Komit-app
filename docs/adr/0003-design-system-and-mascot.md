# 3. Design system, Komo the mascot, and brand assets

Date: 2026-10-28 · Status: accepted (revised the same day, see "Revision")

## Context

Komit's look was close to Material defaults: system font, hard-coded sizes and colors in
screens, no motion vocabulary, the default launcher icon, a blank splash and a one-form
onboarding. The user asked for a distinctive art direction, a mascot named Komo, haptic
feedback and a better first run.

A first pass chose a calm "paper journal" direction (cream paper, the Fraunces serif, flat
cards). The user rejected it: they like the style of Supercell's mobile games (Clash Royale,
Brawl Stars, Squad Busters) and want the app icon to be Komo's face filling the whole icon,
not Komo standing on a background.

The product's signature is the day grid: every logged day is a small colored square. The
design system still grows from that, now as game tiles.

## Decision

### Concept: "a pocket arcade for your habits"

Chunky, outlined, glossy, bouncy, inspired by the mobile-game look but entirely original:
no Supercell font (Supercell-Magic is proprietary), character, logo, asset or trademark is
used or imitated. Komit stays a daily productivity tool: the playful energy goes into
outlines, gloss, color and motion, while text stays large, high-contrast and calm.

The full token sheet and layout rules live in `docs/design/art-direction.md`.

- **Palette.** Sunburst amber `#FFBC1F` (Komo, primary actions), plum ink `#2A1F3D` (text
  and every outline; violet-tinted so it ties amber and grape together), grape `#6B3FE0`
  (notes, statistics hero), flame `#FF7A1A` (current streak), mint `#2EC27E` (Komo's sprout),
  tomato `#D92D20` (destructive actions). Light surfaces are warm cream `#FFF4DC` with white
  cards; the dark theme is a deep indigo "night arcade" (`#1A1736`, cards `#28234F`) rather
  than grey, so it stays colorful. Amber is too light on cream for text, so
  `KomitColors.accentText` (deep amber `#8A4B00` by day) carries amber text and focus.
- **Typography.** Lilita One (SIL OFL 1.1, 28 KB, one heavy rounded condensed weight) for
  display, headline and `titleLarge` styles and button labels; Nunito (SIL OFL 1.1, one
  variable file, weight axis driven by `fontWeight`) for everything else, at weight 600 for
  body and 800 for labels. Both cover French. Titles on saturated colors get a dark outline
  made of text shadows (`outlinedTextShadows`), so a title stays one `Text`: one semantics
  node, and it scales with the user's font size. Page titles get a hard amber drop shadow.
- **Outline and depth.** `AppOutline` (thin 2, regular 2.5, heavy 3) draws every component;
  `AppDepth` sets the darker band under buttons (5, compact 4, icon 4) and the cards' soft
  drop shadow. Depth colors of user colors come from `depthShadeOf` (HSL lightness − 0.16).
- **Components** (`lib/core/ui`): `GamePressable` (press, focus, keyboard, semantics and the
  press haptic, shared by every control), `GameButton` (primary, neutral, danger tones or a
  custom face color, compact size, selected state), `GameIconButton`, `GameBackButton`,
  `GameCard` (thin inner highlight line, outline, soft shadow; pressable with `onTap`),
  `GameBadge`, `GameTag`, `GameProgressBar`, `GameTitle`, all painted by one
  `GameSurfacePainter`. Material widgets that remain (fields, switches, radios, dialogs,
  sheets, snack bars, the navigation bar, date and time pickers) are themed with the same
  outlines and colors.
- **Motion.** A button's face sinks into its band in 70 ms and springs back with an elastic
  overshoot in 320 ms (`AppCurves.pressRelease`); cards shrink to 96 % and bounce back;
  progress bars fill with an overshoot (`AppCurves.overshoot`); a logged day still pops into
  its cell. `motionAwareDuration` returns zero when the system removes animations, so every
  press still shows its pressed state, just without the animation.
- **Large text.** From a 1.5 text scale (`isLargeTextScale`), the dashboard grid becomes a
  single column and the habit hero card stacks its badge above the title, so words are not
  cut mid-word; card heights grow with the text scale.

### Komo

- An amber day tile with a mint sprout, now drawn like a sticker: thick ink outline around
  the body, sprout, leaves and arms, a darker bottom band, a glossy highlight, big tall eyes
  with two highlights, coral cheeks. Drawn by a `CustomPainter` in a 100-unit design box
  (`KomoGeometry`); no bitmap asset.
- Moods (`KomoMood`, public API unchanged): `idle` (a small squash-and-stretch hop, a pause,
  a blink), `happy` (big hops with anticipation squash, landing squash, raised arms, outlined
  four-point sparkles), `sleepy` (eyes closed, drooping sprout, rising "z"), `waving` (bobbing
  with each swing of the arm). Poses stay pure periodic functions of the cycle progress
  (`KomoPose.of`), so the animation can stop on any cycle boundary without a jump.
- `KomoMascot(mood:, size:, semanticLabel:)` and `KomoEmptyState(mood:, title:, message:,
  action:, mascotSize:)` keep their signatures. The 12-second animation budget,
  tap-to-replay and reduced-motion behavior are unchanged.

### Haptics

`KomitHaptics` gains `press()` (a selection tick), played by `GamePressable` when a chunky
control goes down. `celebration()` now also plays when a log completes the day (every habit
logged today, computed by `isEveryHabitLoggedOn`, which also drives Komo's happy mood on the
dashboard).

### Brand assets on Android

- **Launcher icon: Komo's face is the icon.** The adaptive background is Komo's body color
  edge to edge (a soft vertical sunburst gradient, no shape edge); the foreground holds only
  the big eyes, cheeks and a tiny smile, inside the 66 dp safe circle. The Android 13+
  monochrome layer is the eyes only, highlights cut out.
- `docs/design/komit-launcher-icon.svg` is the source of truth; the legacy PNGs (API 24-25)
  are rendered from it offline by `tool/render_launcher_icons.swift`, using macOS's own SVG
  renderer (no dependency, no network).
- Splash: Android 12+ shows the face on a sunburst icon circle over the brand background
  (cream, night indigo in dark mode); earlier versions draw the same with a layer-list.
- The notification small icon `ic_stat_komo` stays Komo's monochrome silhouette.

## Alternatives rejected

- **The paper-journal direction (Fraunces serif, flat cards)**: rejected by the user; too
  quiet for the game-like energy they want.
- **Copying a Supercell font or UI kit**: proprietary; Lilita One and Nunito give a similar
  chunky, friendly voice under the OFL.
- **Lilita One for body text**: one weight, condensed and heavy; tiring in paragraphs and
  lists. Nunito keeps the rounded feel while staying legible.
- **A real text stroke drawn by a second `Text` with a stroke paint**: doubles every title
  for screen readers and tests; shadows give the same look in one widget.
- **Lottie, Rive or an animation package**: a dependency and an asset pipeline for a few
  moods and presses; painters and implicit animations cover it and stay themeable.
- **Komo standing on a background for the icon**: explicitly rejected by the user.

## Revision

The first version of this record chose Fraunces, a cream paper palette and flat cards. It
was replaced the same day by the game direction above at the user's request; Fraunces and
its license registration were removed from the app.

## Consequences

- New UI uses the `Game*` components and the tokens (`AppOutline`, `AppDepth`, `AppRadii`,
  `AppSizes`, `AppDurations`, `AppCurves`, `KomitColors`); no raw colors, sizes or durations
  in screens.
- Changing the icon means editing the SVG, mirroring it in the three adaptive drawables and
  re-running `swift tool/render_launcher_icons.swift`.
- The APK carries about 305 KB of fonts (Lilita One and Nunito) instead of 360 KB.
