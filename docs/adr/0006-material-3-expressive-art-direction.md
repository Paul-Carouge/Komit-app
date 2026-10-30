# 6. Material 3 Expressive art direction

Date: 2026-10-29 · Status: accepted · Supersedes the visual style of [0003](0003-design-system-and-mascot.md)

## Context

ADR 0003 gave Komit a "living paper" look: cream surface, amber, the Fraunces serif and a
detailed Komo. The user then tried a game style (Supercell) and rejected it, rejected the
serif and the detailed icon and mascot, and asked for something "smoother, cleaner, in the
Material 3 Expressive style with premium iOS-like effects adapted to Android", with a
minimal icon: "all orange with just two pill eyes".

## Decision

- **Style**: Material 3 Expressive on Roboto, with iOS-like premium touches kept native to
  Android: frosted translucent bars (`FrostedGlass`), large titles that collapse
  (`LargeTitleSliverAppBar`), spring presses (`PressableCard`), soft diffuse shadows in light
  mode and stepped surfaces in dark mode, haptics on every meaningful action.
- **Palette**: brand orange `#FF8C1A` (`#FF9D42` at night) on a warm neutral page
  (`#F6F4F1` / `#0F0E0D`); `accentText` carries orange text at WCAG AA.
- **Icon and Komo**: the launcher icon is an orange square with two pill eyes, and Komo is the
  same shape come alive, with moods only in motion and eyes. Holiday accessories are the
  only additions.
- **Home**: a list of habit rows, not a grid.
- **Voice**: French says "tu".
- The living reference is `docs/design/design-system.md`; tokens live in
  `lib/core/theme/app_theme.dart` and `app_motion.dart`. Screens use tokens only.

## Consequences

New screens reuse the shared widgets and tokens, so they inherit the style; anything that
needs a new color, size or duration adds a named token first. The rejected directions are
listed in the design system so they are not proposed again.
