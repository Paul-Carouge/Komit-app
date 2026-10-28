import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/calendar_day.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../shared/day_grid.dart';

const int _maximumDaysInMonth = 31;
const double _dayLabelColumnWidth = 24;

/// One column per month, one row per day of the month, like a paper habit tracker.
class YearlyGrid extends StatelessWidget {
  const YearlyGrid({
    required this.year,
    required this.today,
    required this.habit,
    required this.objectiveIdByDay,
    required this.onDayTapped,
    super.key,
  });

  final int year;
  final CalendarDay today;
  final HabitWithObjectives habit;
  final Map<CalendarDay, int> objectiveIdByDay;
  final ValueChanged<CalendarDay> onDayTapped;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    final monthInitialFormat = DateFormat('MMMMM', languageTag);
    final fullDateFormat = DateFormat.yMMMMd(languageTag);
    final labelStyle = textTheme.labelSmall?.copyWith(color: komitColors.mutedText);

    final cells = <DayGridCell>[];
    for (var dayOfMonth = 1; dayOfMonth <= _maximumDaysInMonth; dayOfMonth++) {
      for (var month = 1; month <= DateTime.monthsPerYear; month++) {
        cells.add(_cellFor(month, dayOfMonth, komitColors, fullDateFormat));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - _dayLabelColumnWidth;
        const cellGap = AppSpacing.extraSmall;
        final cellSize = (gridWidth - cellGap * (DateTime.monthsPerYear - 1)) / DateTime.monthsPerYear;
        return Column(
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  const SizedBox(width: _dayLabelColumnWidth),
                  for (var month = 1; month <= DateTime.monthsPerYear; month++)
                    Expanded(
                      child: Text(
                        monthInitialFormat.format(DateTime(year, month)),
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: _dayLabelColumnWidth,
                    child: Column(
                      children: [
                        for (var dayOfMonth = 1; dayOfMonth <= _maximumDaysInMonth; dayOfMonth++)
                          Container(
                            height: cellSize,
                            margin: EdgeInsets.only(bottom: dayOfMonth == _maximumDaysInMonth ? 0 : cellGap),
                            alignment: Alignment.center,
                            child: FittedBox(child: Text('$dayOfMonth', style: labelStyle)),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: DayGrid(columnCount: DateTime.monthsPerYear, cells: cells, cellGap: cellGap),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  DayGridCell _cellFor(int month, int dayOfMonth, KomitColors komitColors, DateFormat fullDateFormat) {
    final isRealDate = DateTime.utc(year, month, dayOfMonth).month == month;
    if (!isRealDate) return const DayGridCell(color: null, semanticLabel: '');
    final day = CalendarDay.fromDate(year, month, dayOfMonth);
    final objectiveId = objectiveIdByDay[day];
    final objective = objectiveId == null ? null : habit.objectiveWithId(objectiveId);
    final isFuture = day.isAfter(today);
    return DayGridCell(
      color: objective != null
          ? Color(objective.colorArgb)
          : isFuture
          ? komitColors.futureCell
          : komitColors.emptyCell,
      isLogged: objective != null,
      semanticLabel: '${fullDateFormat.format(day.asLocalDate)}: ${objective?.title ?? '-'}',
      // Future days cannot be logged: the old app allowed it and produced misleading streaks.
      // An imported future log stays tappable so it can be cleared.
      onTap: isFuture && objective == null ? null : () => onDayTapped(day),
    );
  }
}
