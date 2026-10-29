import 'package:flutter/widgets.dart';

import '../../domain/seasons.dart';

/// Tells every Komo below which holiday it dresses up for, without each one reading providers.
class KomoSeasonScope extends InheritedWidget {
  const KomoSeasonScope({required this.season, required super.child, super.key});

  final Season? season;

  /// Null outside a scope or on an ordinary day.
  static Season? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<KomoSeasonScope>()?.season;

  @override
  bool updateShouldNotify(KomoSeasonScope oldWidget) => oldWidget.season != season;
}
