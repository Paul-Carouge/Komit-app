import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_theme.dart';

/// One square of a [DayGrid]; a null [color] leaves the slot blank (e.g. February 30).
class DayGridCell {
  const DayGridCell({required this.color, required this.semanticLabel, this.onTap});

  final Color? color;
  final String semanticLabel;
  final VoidCallback? onTap;
}

/// Paints a whole grid of days in one [CustomPaint] instead of hundreds of widgets,
/// while still exposing every cell to screen readers.
class DayGrid extends StatelessWidget {
  const DayGrid({required this.columnCount, required this.cells, this.cellGap = AppSpacing.extraSmall, super.key});

  final int columnCount;

  /// Row-major order; its length must be a multiple of [columnCount].
  final List<DayGridCell> cells;
  final double cellGap;

  int get _rowCount => cells.length ~/ columnCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - cellGap * (columnCount - 1)) / columnCount;
        final height = cellSize * _rowCount + cellGap * (_rowCount - 1);
        final geometry = _DayGridGeometry(columnCount: columnCount, cellSize: cellSize, cellGap: cellGap);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final cellIndex = geometry.cellIndexAt(details.localPosition);
            if (cellIndex != null && cellIndex < cells.length) cells[cellIndex].onTap?.call();
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _DayGridPainter(cells: cells, geometry: geometry),
          ),
        );
      },
    );
  }
}

class _DayGridGeometry {
  const _DayGridGeometry({required this.columnCount, required this.cellSize, required this.cellGap});

  final int columnCount;
  final double cellSize;
  final double cellGap;

  Rect cellRect(int index) {
    final column = index % columnCount;
    final row = index ~/ columnCount;
    return Rect.fromLTWH(column * (cellSize + cellGap), row * (cellSize + cellGap), cellSize, cellSize);
  }

  int? cellIndexAt(Offset position) {
    final pitch = cellSize + cellGap;
    final column = (position.dx / pitch).floor();
    final row = (position.dy / pitch).floor();
    if (column < 0 || column >= columnCount || row < 0) return null;
    return row * columnCount + column;
  }
}

class _DayGridPainter extends CustomPainter {
  _DayGridPainter({required this.cells, required this.geometry});

  final List<DayGridCell> cells;
  final _DayGridGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final radius = Radius.circular(AppRadii.gridCell.clamp(0, geometry.cellSize / 4));
    for (final (index, cell) in cells.indexed) {
      final color = cell.color;
      if (color == null) continue;
      paint.color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(geometry.cellRect(index), radius), paint);
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final (index, cell) in cells.indexed)
          if (cell.color != null)
            CustomPainterSemantics(
              rect: geometry.cellRect(index),
              properties: SemanticsProperties(
                label: cell.semanticLabel,
                button: cell.onTap != null,
                onTap: cell.onTap,
                textDirection: TextDirection.ltr,
              ),
            ),
      ];

  @override
  bool shouldRepaint(_DayGridPainter oldDelegate) =>
      !identical(oldDelegate.cells, cells) || oldDelegate.geometry.cellSize != geometry.cellSize;

  @override
  bool shouldRebuildSemantics(_DayGridPainter oldDelegate) => shouldRepaint(oldDelegate);
}
