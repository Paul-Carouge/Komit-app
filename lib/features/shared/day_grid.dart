import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

/// One square of a [DayGrid]; a null [color] leaves the slot blank (e.g. February 30).
class DayGridCell {
  const DayGridCell({required this.color, required this.semanticLabel, this.onTap, this.isOutlined = false});

  final Color? color;
  final String semanticLabel;
  final VoidCallback? onTap;

  /// Rings the cell, to point out today among the other days.
  final bool isOutlined;
}

/// More changed cells than this at once is a data swap (another year, a new day), not a log:
/// those cells change silently instead of all popping at the same time.
const int _maximumChangedCellsAnimatedAsLog = 2;

/// A popping cell starts at this share of its size, then overshoots back to full size.
const double _poppingCellInitialScale = 0.4;

/// The ring around a popping cell grows by this share of the cell size while fading out.
const double _poppingRingGrowth = 0.6;

/// Paints a whole grid of days in one [CustomPaint] instead of hundreds of widgets,
/// while still exposing every cell to screen readers.
///
/// When one or two cells change color (a day was just logged or cleared), they pop into place.
class DayGrid extends StatefulWidget {
  const DayGrid({
    required this.columnCount,
    required this.cells,
    this.cellGap = AppSpacing.extraSmall,
    this.cellTapActionLabel,
    this.minimumRowExtent = 0,
    super.key,
  });

  final int columnCount;

  /// Each row is at least this tall, its cells centered in it: a small cell then still has a
  /// tall enough touch target, and screen readers focus the whole slot.
  final double minimumRowExtent;

  /// Screen readers offer a cell's tap as a named action rather than a button: a cell is far
  /// smaller than a 48 dp touch target, and the screen offers a full-size control for the same job.
  final String? cellTapActionLabel;

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
        final rowExtent = cellSize < widget.minimumRowExtent ? widget.minimumRowExtent : cellSize;
        final height = rowExtent * _rowCount + cellGap * (_rowCount - 1);
        final geometry = _DayGridGeometry(
          columnCount: widget.columnCount,
          cellSize: cellSize,
          cellGap: cellGap,
          rowExtent: rowExtent,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Each cell exposes its own action; a tap on the whole grid would mean nothing.
          excludeFromSemantics: true,
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
              cellTapActionLabel: widget.cellTapActionLabel,
              outlineColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}

class _DayGridGeometry {
  const _DayGridGeometry({
    required this.columnCount,
    required this.cellSize,
    required this.cellGap,
    required this.rowExtent,
  });

  final int columnCount;
  final double cellSize;
  final double cellGap;
  final double rowExtent;

  /// The cell's column and row slot: where it is tapped and what screen readers focus.
  Rect slotRect(int index) {
    final column = index % columnCount;
    final row = index ~/ columnCount;
    return Rect.fromLTWH(column * (cellSize + cellGap), row * (rowExtent + cellGap), cellSize, rowExtent);
  }

  Rect cellRect(int index) {
    final slot = slotRect(index);
    return Rect.fromCenter(center: slot.center, width: cellSize, height: cellSize);
  }

  int? cellIndexAt(Offset position) {
    final column = (position.dx / (cellSize + cellGap)).floor();
    final row = (position.dy / (rowExtent + cellGap)).floor();
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
    required this.cellTapActionLabel,
    required this.outlineColor,
  }) : super(repaint: popAnimation);

  final List<DayGridCell> cells;
  final _DayGridGeometry geometry;
  final AnimationController popAnimation;
  final Map<int, Color?> previousColorByPoppingCellIndex;
  final String? cellTapActionLabel;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final radius = Radius.circular(AppRadii.gridCell.clamp(0, geometry.cellSize / 4));
    final isPopping = popAnimation.isAnimating;
    for (final (index, cell) in cells.indexed) {
      final color = cell.color;
      if (color == null) continue;
      if (cell.isOutlined) _paintOutline(canvas, index, radius);
      if (isPopping && previousColorByPoppingCellIndex.containsKey(index)) {
        _paintPoppingCell(canvas, paint, index, color, radius);
        continue;
      }
      paint.color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(geometry.cellRect(index), radius), paint);
    }
  }

  /// Drawn outside the cell, in the gap, so the cell keeps its full colored area.
  void _paintOutline(Canvas canvas, int index, Radius radius) {
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.emphasisBorderWidth
      ..color = outlineColor;
    final outlineRect = geometry.cellRect(index).inflate(AppSizes.emphasisBorderWidth);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outlineRect, radius + const Radius.circular(AppSizes.emphasisBorderWidth)),
      outlinePaint,
    );
  }

  void _paintPoppingCell(Canvas canvas, Paint paint, int index, Color color, Radius radius) {
    final progress = popAnimation.value;
    final cellRect = geometry.cellRect(index);
    final previousColor = previousColorByPoppingCellIndex[index];
    // The old color stays underneath while the new one grows from the center.
    if (previousColor != null) {
      paint.color = previousColor;
      canvas.drawRRect(RRect.fromRectAndRadius(cellRect, radius), paint);
    }
    final scale = _poppingCellInitialScale + (1 - _poppingCellInitialScale) * AppCurves.emphasized.transform(progress);
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: cellRect.center, width: cellRect.width * scale, height: cellRect.height * scale),
        radius,
      ),
      paint,
    );
    final ringRect = cellRect.inflate(geometry.cellSize * _poppingRingGrowth * AppCurves.standard.transform(progress));
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.emphasisBorderWidth
      ..color = color.withValues(alpha: color.a * (1 - progress));
    canvas.drawRRect(RRect.fromRectAndRadius(ringRect, radius), ringPaint);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    final actionLabel = cellTapActionLabel;
    final cellTapAction = actionLabel == null ? null : CustomSemanticsAction(label: actionLabel);
    return (size) => [
      for (final (index, cell) in cells.indexed)
        if (cell.color != null)
          CustomPainterSemantics(
            rect: geometry.slotRect(index),
            properties: switch ((cell.onTap, cellTapAction)) {
              (final onTap?, final cellTapAction?) => SemanticsProperties(
                label: cell.semanticLabel,
                customSemanticsActions: {cellTapAction: onTap},
                textDirection: TextDirection.ltr,
              ),
              (final onTap, _) => SemanticsProperties(
                label: cell.semanticLabel,
                button: onTap != null,
                onTap: onTap,
                textDirection: TextDirection.ltr,
              ),
            },
          ),
    ];
  }

  @override
  bool shouldRepaint(_DayGridPainter oldDelegate) =>
      !identical(oldDelegate.cells, cells) ||
      oldDelegate.geometry.cellSize != geometry.cellSize ||
      oldDelegate.geometry.rowExtent != geometry.rowExtent ||
      oldDelegate.outlineColor != outlineColor ||
      !identical(oldDelegate.previousColorByPoppingCellIndex, previousColorByPoppingCellIndex);

  @override
  bool shouldRebuildSemantics(_DayGridPainter oldDelegate) =>
      !identical(oldDelegate.cells, cells) ||
      oldDelegate.geometry.cellSize != geometry.cellSize ||
      oldDelegate.geometry.rowExtent != geometry.rowExtent ||
      oldDelegate.cellTapActionLabel != cellTapActionLabel;
}
