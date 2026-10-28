import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icons are stored by name so the database never depends on font code points.
/// Map literal keeps every icon const, so unused glyphs are still tree-shaken.
const Map<String, IconData> habitIconsByName = {
  'footprints': LucideIcons.footprints,
  'stethoscope': LucideIcons.stethoscope,
  'bookOpen': LucideIcons.bookOpen,
  'dumbbell': LucideIcons.dumbbell,
  'glassWater': LucideIcons.glassWater,
  'heartPulse': LucideIcons.heartPulse,
  'pill': LucideIcons.pill,
  'dollarSign': LucideIcons.dollarSign,
  'bike': LucideIcons.bike,
  'waves': LucideIcons.waves,
  'mountain': LucideIcons.mountain,
  'brain': LucideIcons.brain,
  'smile': LucideIcons.smile,
  'frown': LucideIcons.frown,
  'moon': LucideIcons.moon,
  'sun': LucideIcons.sun,
  'bed': LucideIcons.bed,
  'coffee': LucideIcons.coffee,
  'apple': LucideIcons.apple,
  'carrot': LucideIcons.carrot,
  'salad': LucideIcons.salad,
  'cigaretteOff': LucideIcons.cigaretteOff,
  'wineOff': LucideIcons.wineOff,
  'phoneOff': LucideIcons.phoneOff,
  'music': LucideIcons.music,
  'guitar': LucideIcons.guitar,
  'pencil': LucideIcons.pencil,
  'code': LucideIcons.code,
  'laptop': LucideIcons.laptop,
  'languages': LucideIcons.languages,
  'graduationCap': LucideIcons.graduationCap,
  'leaf': LucideIcons.leaf,
  'flower2': LucideIcons.flower2,
  'dog': LucideIcons.dog,
  'cat': LucideIcons.cat,
  'house': LucideIcons.house,
  'sparkles': LucideIcons.sparkles,
  'brush': LucideIcons.brush,
  'showerHead': LucideIcons.showerHead,
  'timer': LucideIcons.timer,
  'alarmClock': LucideIcons.alarmClock,
  'wallet': LucideIcons.wallet,
  'piggyBank': LucideIcons.piggyBank,
  'users': LucideIcons.users,
  'heart': LucideIcons.heart,
  'flame': LucideIcons.flame,
  'target': LucideIcons.target,
  'trophy': LucideIcons.trophy,
  'star': LucideIcons.star,
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
