import 'package:flutter/widgets.dart';

/// The Lucide glyphs Komit uses, drawn from `assets/fonts/lucide.ttf` (ISC, see
/// `registerThirdPartyLicenses`). Vendored instead of `lucide_icons_flutter`, whose six
/// variable-weight fonts are bundled whole (1.4 MB compressed) while icon tree shaking keeps only
/// the glyphs referenced here from this font.
///
/// To add an icon, look up its code point in `assets/fonts/lucide_codepoints.json`.
abstract final class KomitIcons {
  static const IconData alarmClock = IconData(0xe03a, fontFamily: _fontFamily);
  static const IconData apple = IconData(0xe34e, fontFamily: _fontFamily);
  static const IconData archive = IconData(0xe041, fontFamily: _fontFamily);
  static const IconData archiveRestore = IconData(0xe2cd, fontFamily: _fontFamily);
  static const IconData arrowRight = IconData(0xe049, fontFamily: _fontFamily);
  static const IconData bed = IconData(0xe2c1, fontFamily: _fontFamily);
  static const IconData bell = IconData(0xe059, fontFamily: _fontFamily);
  static const IconData bellOff = IconData(0xe05a, fontFamily: _fontFamily);
  static const IconData bellRing = IconData(0xe224, fontFamily: _fontFamily);
  static const IconData bike = IconData(0xe1d2, fontFamily: _fontFamily);
  static const IconData bookOpen = IconData(0xe05f, fontFamily: _fontFamily);
  static const IconData brain = IconData(0xe3c6, fontFamily: _fontFamily);
  static const IconData brush = IconData(0xe1d3, fontFamily: _fontFamily);
  static const IconData calendar = IconData(0xe063, fontFamily: _fontFamily);
  static const IconData calendarCheck = IconData(0xe2b7, fontFamily: _fontFamily);
  static const IconData calendarClock = IconData(0xe304, fontFamily: _fontFamily);
  static const IconData calendarPlus = IconData(0xe2bc, fontFamily: _fontFamily);
  static const IconData carrot = IconData(0xe25a, fontFamily: _fontFamily);
  static const IconData cat = IconData(0xe38c, fontFamily: _fontFamily);
  static const IconData chartNoAxesColumn = IconData(0xe068, fontFamily: _fontFamily);
  static const IconData check = IconData(0xe06c, fontFamily: _fontFamily);
  static const IconData chevronDown = IconData(0xe06d, fontFamily: _fontFamily);
  static const IconData chevronLeft = IconData(0xe06e, fontFamily: _fontFamily);
  static const IconData chevronRight = IconData(0xe06f, fontFamily: _fontFamily);
  static const IconData cigaretteOff = IconData(0xe2c7, fontFamily: _fontFamily);
  static const IconData cloudOff = IconData(0xe08d, fontFamily: _fontFamily);
  static const IconData code = IconData(0xe093, fontFamily: _fontFamily);
  static const IconData coffee = IconData(0xe096, fontFamily: _fontFamily);
  static const IconData dog = IconData(0xe38d, fontFamily: _fontFamily);
  static const IconData dollarSign = IconData(0xe0b1, fontFamily: _fontFamily);
  static const IconData download = IconData(0xe0b2, fontFamily: _fontFamily);
  static const IconData dumbbell = IconData(0xe3a1, fontFamily: _fontFamily);
  static const IconData ellipsis = IconData(0xe0b6, fontFamily: _fontFamily);
  static const IconData eraser = IconData(0xe28f, fontFamily: _fontFamily);
  static const IconData externalLink = IconData(0xe0b9, fontFamily: _fontFamily);
  static const IconData eye = IconData(0xe0ba, fontFamily: _fontFamily);
  static const IconData eyeOff = IconData(0xe0bb, fontFamily: _fontFamily);
  static const IconData fileJson = IconData(0xe36b, fontFamily: _fontFamily);
  static const IconData fingerprint = IconData(0xe2cb, fontFamily: _fontFamily);
  static const IconData flame = IconData(0xe0d2, fontFamily: _fontFamily);
  static const IconData flower2 = IconData(0xe2d4, fontFamily: _fontFamily);
  static const IconData footprints = IconData(0xe3b9, fontFamily: _fontFamily);
  static const IconData frown = IconData(0xe0db, fontFamily: _fontFamily);
  static const IconData glassWater = IconData(0xe2d5, fontFamily: _fontFamily);
  static const IconData globe = IconData(0xe0e8, fontFamily: _fontFamily);
  static const IconData graduationCap = IconData(0xe234, fontFamily: _fontFamily);
  static const IconData gripVertical = IconData(0xe0eb, fontFamily: _fontFamily);
  static const IconData guitar = IconData(0xe55f, fontFamily: _fontFamily);
  static const IconData heart = IconData(0xe0f2, fontFamily: _fontFamily);
  static const IconData heartPulse = IconData(0xe36e, fontFamily: _fontFamily);
  static const IconData history = IconData(0xe1f5, fontFamily: _fontFamily);
  static const IconData house = IconData(0xe0f5, fontFamily: _fontFamily);
  static const IconData info = IconData(0xe0f9, fontFamily: _fontFamily);
  static const IconData languages = IconData(0xe0fe, fontFamily: _fontFamily);
  static const IconData laptop = IconData(0xe1cd, fontFamily: _fontFamily);
  static const IconData leaf = IconData(0xe2de, fontFamily: _fontFamily);
  static const IconData lock = IconData(0xe10b, fontFamily: _fontFamily);
  static const IconData lockKeyhole = IconData(0xe531, fontFamily: _fontFamily);
  static const IconData minus = IconData(0xe11c, fontFamily: _fontFamily);
  static const IconData moon = IconData(0xe11e, fontFamily: _fontFamily);
  static const IconData mountain = IconData(0xe231, fontFamily: _fontFamily);
  static const IconData music = IconData(0xe122, fontFamily: _fontFamily);
  static const IconData notebookPen = IconData(0xe596, fontFamily: _fontFamily);
  static const IconData pencil = IconData(0xe1f9, fontFamily: _fontFamily);
  static const IconData phoneOff = IconData(0xe138, fontFamily: _fontFamily);
  static const IconData piggyBank = IconData(0xe13a, fontFamily: _fontFamily);
  static const IconData pill = IconData(0xe3bd, fontFamily: _fontFamily);
  static const IconData plus = IconData(0xe13d, fontFamily: _fontFamily);
  static const IconData power = IconData(0xe140, fontFamily: _fontFamily);
  static const IconData refreshCw = IconData(0xe145, fontFamily: _fontFamily);
  static const IconData rotateCw = IconData(0xe149, fontFamily: _fontFamily);
  static const IconData salad = IconData(0xe3a8, fontFamily: _fontFamily);
  static const IconData scrollText = IconData(0xe45f, fontFamily: _fontFamily);
  static const IconData settings = IconData(0xe154, fontFamily: _fontFamily);
  static const IconData shieldCheck = IconData(0xe1ff, fontFamily: _fontFamily);
  static const IconData showerHead = IconData(0xe37c, fontFamily: _fontFamily);
  static const IconData smartphone = IconData(0xe163, fontFamily: _fontFamily);
  static const IconData smile = IconData(0xe164, fontFamily: _fontFamily);
  static const IconData sparkles = IconData(0xe412, fontFamily: _fontFamily);
  static const IconData star = IconData(0xe176, fontFamily: _fontFamily);
  static const IconData stethoscope = IconData(0xe2f1, fontFamily: _fontFamily);
  static const IconData sun = IconData(0xe178, fontFamily: _fontFamily);
  static const IconData target = IconData(0xe180, fontFamily: _fontFamily);
  static const IconData timer = IconData(0xe1e0, fontFamily: _fontFamily);
  static const IconData trash2 = IconData(0xe18e, fontFamily: _fontFamily);
  static const IconData trophy = IconData(0xe373, fontFamily: _fontFamily);
  static const IconData upload = IconData(0xe19e, fontFamily: _fontFamily);
  static const IconData users = IconData(0xe1a4, fontFamily: _fontFamily);
  static const IconData vibrate = IconData(0xe223, fontFamily: _fontFamily);
  static const IconData wallet = IconData(0xe204, fontFamily: _fontFamily);
  static const IconData waves = IconData(0xe283, fontFamily: _fontFamily);
  static const IconData wineOff = IconData(0xe3a0, fontFamily: _fontFamily);
  static const IconData x = IconData(0xe1b2, fontFamily: _fontFamily);

  static const String _fontFamily = 'Lucide';
}
