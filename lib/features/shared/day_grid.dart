import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

/// One square of a [DayGrid]; a null [color] leaves the slot blank (e.g. February 30).
class DayGridCell {
  const DayGridCell({required this.color, required this.semanticLabel, this.onTap, this.isLogged = false});

  final Color? color;

  /// Logged days are drawn as tiny raised game tiles, with a darker band under their face.
  final bool isLogged;
  final String semanticLabel;
  final VoidCallback? onTap;
}

/// More changed cells than this at once is a data swap (another year, a new day), not a log:
/// those cells change silently instead of all popping at the same time.
const int _maximumChangedCellsAnimatedAsLog = 2;

/// A popping cell starts at this share of its size, then overshoots back to full size.
const double _poppingCellInitialScale = 0.4;

/// The ring around a popping cell grows by this share of the cell size while fading out.
const double _poppingRingGrowth = 0.6;

/// Height of a logged cell's darker bottom band, as a share of the cell size.
const double _loggedCellDepthShare = 0.2;

/// Paints a whole grid of days in one [CustomPaint] instead of hundreds of widgets,
/// while still exposing every cell to screen readers.
///
/// When one or two cells change color (a day was just logged or cleared), they pop into place.
class DayGrid extends StatefulWidget {
  const DayGrid({required this.columnCount, required this.cells, this.cellGap = AppSpacing.extraSmall, super.key});

  final int columnCount;

  /// Row-major order; its length must be a multiple of [columnCount].
  final List<DayGridCell> cells;
  final double cellGap;

  @override
  State<DayGrid> createState() => _DayGridState();
}

class _DayGridState extends State<DayGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _popController = AnimationController(vsync: this, duration: AppDurations.emphasized);

  /// Previous color of each popping cell, by cell index.
  Map<int, Color?> _previousColorByPoppingCellIndex = const {};

  @override
  void didUpdateWidget(DayGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (MediaQuery.disableAnimationsOf(context) || oldWidget.cells.length != widget.cells.length) return;
    final previousColorByChangedCellIndex = <int, Color?>{};
    for (final (index, cell) in widget.cells.indexed) {
      final previousColor = oldWidget.cells[index].color;
      if (cell.color == previousColor) continue;
      previousColorByChangedCellIndex[index] = previousColor;
      if (previousColorByChangedCellIndex.length > _maximumChangedCellsAnimatedAsLog) return;
    }
    if (previousColorByChangedCellIndex.isEmpty) return;
    _previousColorByPoppingCellIndex = previousColorByChangedCellIndex;
    _popController.forward(from: 0);
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  int get _rowCount => widget.cells.length ~/ widget.columnCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellGap = widget.cellGap;
        final cellSize = (constraints.maxWidth - cellGap * (widget.columnCount - 1)) / widget.columnCount;
        final height = cellSize * _rowCount + cellGap * (_rowCount - 1);
        final geometry = _DayGridGeometry(columnCount: widget.columnCount, cellSize: cellSize, cellGap: cellGap);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final cellIndex = geometry.cellIndexAt(details.localPosition);
            if (cellIndex != null && cellIndex < widget.cells.length) widget.cells[cellIndex].onTap?.call();
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _DayGridPainter(
              cells: widget.cells,
              geometry: geometry,
              popAnimation: _popController,
              previousColorByPoppingCellIndex: _previousColorByPoppingCellIndex,
            ),
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
  _DayGridPainter({
    required this.cells,
    required this.geometry,
    required this.popAnimation,
    required this.previousColorByPoppingCellIndex,
  }) : super(repaint: popAnimation);

  final List<DayGridCell> cells;
  final _DayGridGeometry geometry;
  final AnimationController popAnimation;
  final Map<int, Color?> previousColorByPoppingCellIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final radius = Radius.circular(AppRadii.gridCell.clamp(0, geometry.cellSize / 4));
    final isPopping = popAnimation.isAnimating;
    for (final (index, cell) in cells.indexed) {
      final color = cell.color;
      if (color == null) continue;
      if (isPopping && previousColorByPoppingCellIndex.containsKey(index)) {
        _paintPoppingCell(canvas, paint, index, color, radius, isLogged: cell.isLogged);
        continue;
      }
      _paintCell(canvas, paint, geometry.cellRect(index), color, radius, isLogged: cell.isLogged);
    }
  }

  void _paintCell(Canvas canvas, Paint paint, Rect rect, Color color, Radius radius, {required bool isLogged}) {
    if (!isLogged) {
      paint.color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      return;
    }
    paint.color = depthShadeOf(color);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - rect.height * _loggedCellDepthShare),
        radius,
      ),
      paint,
    );
  }

  void _paintPoppingCell(Canvas canvas, Paint paint, int index, Color color, Radius radius, {required bool isLogged}) {
    final progress = popAnimation.value;
    final cellRect = geometry.cellRect(index);
    final previousColor = previousColorByPoppingCellIndex[index];
    // The old color stays underneath while the new one grows from the center.
    if (previousColor != null) {
      paint.color = previousColor;
      canvas.drawRRect(RRect.fromRectAndRadius(cellRect, radius), paint);
    }
    final scale = _poppingCellInitialScale + (1 - _poppingCellInitialScale) * AppCurves.emphasized.transform(progress);
    _paintCell(
      canvas,
      paint,
      Rect.fromCenter(center: cellRect.center, width: cellRect.width * scale, height: cellRect.height * scale),
      color,
      radius,
      isLogged: isLogged,
    );
    final ringRect = cellRect.inflate(geometry.cellSize * _poppingRingGrowth * AppCurves.standard.transform(progress));
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.emphasisBorderWidth
      ..color = color.withValues(alpha: color.a * (1 - progress));
    canvas.drawRRect(RRect.fromRectAndRadius(ringRect, radius), ringPaint);
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
      !identical(oldDelegate.cells, cells) ||
      oldDelegate.geometry.cellSize != geometry.cellSize ||
      !identical(oldDelegate.previousColorByPoppingCellIndex, previousColorByPoppingCellIndex);

  @override
  bool shouldRebuildSemantics(_DayGridPainter oldDelegate) =>
      !identical(oldDelegate.cells, cells) || oldDelegate.geometry.cellSize != geometry.cellSize;
}
