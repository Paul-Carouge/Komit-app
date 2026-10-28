# Komit art direction: "a pocket arcade for your habits"

The decision and its reasons are in `docs/adr/0003-design-system-and-mascot.md`. This page
is the working sheet for anyone adding UI. Code is the source of truth:
`lib/core/theme/app_theme.dart`, `lib/core/theme/app_motion.dart` and `lib/core/ui/`.

## Rules of thumb

1. Every interactive or grouped thing is a sticker: ink outline, rounded corners, a gloss.
2. One amber primary action per screen or sheet; everything else is neutral (white by day,
   raised indigo at night). Red only for actions that delete or replace data.
3. Saturated color is for meaning: habit and objective colors, streak flame, notes grape.
   Pages stay cream or indigo so the colors pop and daily use stays calm.
4. Motion answers a touch: press down, spring back, pop in. Nothing loops for decoration,
   except Komo, and only for 12 seconds.
5. Text stays readable first: body in Nunito 600, at least 4.5:1 contrast, white text on
   color always gets the ink outline.

## Tokens

| Role | Light | Dark |
| --- | --- | --- |
| Page | cream `#FFF4DC` | night `#1A1736` |
| Card, neutral button | white `#FFFFFF` | `#332D63` (buttons), `#28234F` (cards) |
| Ink text and outlines | plum ink `#2A1F3D` | text `#F4F1FF`, outline `#0B0918` |
| Muted text | `#5E5670` (6.3:1 on cream) | `#B7B0DD` (7.1:1 on cards) |
| Primary | sunburst `#FFBC1F`, ink label (9.2:1) | same |
| Notes, statistics hero | grape `#6B3FE0`, white label (6.2:1) | `#7C55F0` |
| Current streak | flame `#FF7A1A`, ink label | same |
| Danger | tomato `#D92D20`, white label (4.8:1) | shaded `#FF8A80` |

- Type: Lilita One for display, headline, `titleLarge`, button labels; Nunito for the rest.
- Outline: 2 (badges, tags, bars), 2.5 (buttons, cards, fields), 3 (hero cards, dialogs).
- Depth: button band 5, compact and icon buttons 4; cards use a soft shadow offset by 4.
- Radii: day cell 5, small 8, badge 14, control 16, button 18, card 22, hero and sheet 28.
- Motion: press down 70 ms, release 320 ms elastic, standard 240 ms, emphasized 520 ms.

## Layout concept

```
Phone (dashboard)                     Large text (>= 150 %)
+------------------------------+      +------------------------------+
| (Komo) Hello, Paul!     [⚙]  |      | (Komo) Hello,           [⚙]  |
| +-----------+ +-----------+  |      |        Paul!                 |
| |[ic] Title | |[ic] Title |  |      | +--------------------------+ |
| | ▦▦▦▦▦▦▦   | | ▦▦▦▦▦▦▦   |  |      | | [ic] Running              | |
| | ▦▦▦▦▦▦▦   | | ▦▦▦▦▦▦▦   |  |      | | ▦▦▦▦▦▦▦ (bigger cells)    | |
| | ⟲ Oct 28  | | ⟲ Oct 27  |  |      | | ⟲ Oct 28                  | |
| +-----------+ +-----------+  |      | +--------------------------+ |
| [ Habits ]       Notes       |      |  ...one card per row          |
+------------------------------+      +------------------------------+

Habit detail                          Log sheet
[←] [📅 2026 ▾]       [▥] [⋯]          Log for 10/28/2026
+==============================+      [  Rest                     ]
| [ic]  RUNNING (outlined)     |      [  5 km                     ]
|       description            |      [  10 km               ✓   ]
+==============================+      [ ⌫ Clear this day (red)    ]
[🔥 Current streak][🏆 Best streak]
Yearly progress      [+ Log today]
+------------------------------+
| month × day grid of tiles    |
+------------------------------+
                [📅 Log another day]
```

Tablets keep the phone column centered at `AppSizes.readableContentMaximumWidth` for text
screens (onboarding, empty states); grids stretch with the window.

## Komo and the icon

- Komo: amber tile body, thick ink outline, glossy top, darker bottom band, mint sprout,
  big tall eyes with two highlights, coral cheeks. Moods: idle, happy, sleepy, waving.
- App icon: Komo's face is the icon. Body color edge to edge, only the eyes, cheeks and a
  tiny smile. Source `docs/design/komit-launcher-icon.svg`; legacy PNGs from
  `swift tool/render_launcher_icons.swift`.
