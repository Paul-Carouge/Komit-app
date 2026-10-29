import 'package:flutter/widgets.dart';

import 'theme/komit_icons.dart';

/// Icons are stored by name so the database never depends on font code points.
/// Map literal keeps every icon const, so unused glyphs are still tree-shaken.
const Map<String, IconData> habitIconsByName = {
  'footprints': KomitIcons.footprints,
  'stethoscope': KomitIcons.stethoscope,
  'bookOpen': KomitIcons.bookOpen,
  'dumbbell': KomitIcons.dumbbell,
  'glassWater': KomitIcons.glassWater,
  'heartPulse': KomitIcons.heartPulse,
  'pill': KomitIcons.pill,
  'dollarSign': KomitIcons.dollarSign,
  'bike': KomitIcons.bike,
  'waves': KomitIcons.waves,
  'mountain': KomitIcons.mountain,
  'brain': KomitIcons.brain,
  'smile': KomitIcons.smile,
  'frown': KomitIcons.frown,
  'moon': KomitIcons.moon,
  'sun': KomitIcons.sun,
  'bed': KomitIcons.bed,
  'coffee': KomitIcons.coffee,
  'apple': KomitIcons.apple,
  'carrot': KomitIcons.carrot,
  'salad': KomitIcons.salad,
  'cigaretteOff': KomitIcons.cigaretteOff,
  'wineOff': KomitIcons.wineOff,
  'phoneOff': KomitIcons.phoneOff,
  'music': KomitIcons.music,
  'guitar': KomitIcons.guitar,
  'pencil': KomitIcons.pencil,
  'code': KomitIcons.code,
  'laptop': KomitIcons.laptop,
  'languages': KomitIcons.languages,
  'graduationCap': KomitIcons.graduationCap,
  'leaf': KomitIcons.leaf,
  'flower2': KomitIcons.flower2,
  'dog': KomitIcons.dog,
  'cat': KomitIcons.cat,
  'house': KomitIcons.house,
  'sparkles': KomitIcons.sparkles,
  'brush': KomitIcons.brush,
  'showerHead': KomitIcons.showerHead,
  'timer': KomitIcons.timer,
  'alarmClock': KomitIcons.alarmClock,
  'wallet': KomitIcons.wallet,
  'piggyBank': KomitIcons.piggyBank,
  'users': KomitIcons.users,
  'heart': KomitIcons.heart,
  'flame': KomitIcons.flame,
  'target': KomitIcons.target,
  'trophy': KomitIcons.trophy,
  'star': KomitIcons.star,
};

const String defaultHabitIconName = 'target';

/// Names used by the original Komit app that differ from the current ones.
const Map<String, String> _legacyIconNameAliases = {'dollar': 'dollarSign'};

IconData habitIconForName(String iconName) =>
    habitIconsByName[iconName] ??
    habitIconsByName[_legacyIconNameAliases[iconName]] ??
    habitIconsByName[defaultHabitIconName]!;

/// Readable on both light and dark surfaces; includes every color of the original app's objectives.
const List<int> habitColorPaletteArgb = [
  0xFFF141CE,
  0xFFEC407A,
  0xFFEF5350,
  0xFFE50A06,
  0xFFFF7043,
  0xFFF9B125,
  0xFFFFCA28,
  0xFFD4E157,
  0xFF9CCC65,
  0xFF66BB6A,
  0xFF26A69A,
  0xFF25DBF9,
  0xFF42A5F5,
  0xFF7A89F0,
  0xFF5C6BC0,
  0xFF7E57C2,
  0xFF7925F9,
  0xFFAB47BC,
  0xFF8D6E63,
  0xFF78909C,
];
