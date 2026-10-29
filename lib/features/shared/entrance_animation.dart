import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/app_motion.dart';

/// How a list row appears, decided once per row by [ListEntranceChoreographer].
sealed class RowEntrance {
  const RowEntrance();
}

/// One of the first rows on screen: fades and rises after [delay], in turn with the others.
class StaggeredRowEntrance extends RowEntrance {
  const StaggeredRowEntrance(this.delay);

  final Duration delay;
}

/// A row added while the list is on screen: it opens room for itself, then fades in.
class InsertedRowEntrance extends RowEntrance {
  const InsertedRowEntrance();
}

/// Decides which rows of a list animate in: the first [maximumStaggeredEntranceCount] rows of
/// the first build, staggered, then any row inserted later. A row scrolled back into view, a
/// row moved, or a rebuild never animates again.
class ListEntranceChoreographer {
  Set<Object>? _initialRowIds;
  final Set<Object> _enteredRowIds = {};
  bool _isInitialEntranceOver = false;

  /// Call on every build with the ids of every row, built or not.
  void updateRowIds(Iterable<Object> rowIds) {
    final currentRowIds = rowIds.toSet();
    if (_initialRowIds == null) {
      _initialRowIds = currentRowIds;
      // Rows built after the first frame (scrolled into view) are not part of the entrance.
      SchedulerBinding.instance.addPostFrameCallback((_) => _isInitialEntranceOver = true);
    }
    // A row that leaves (archived, deleted) and comes back counts as inserted.
    _enteredRowIds.retainAll(currentRowIds);
    _initialRowIds!.retainAll(currentRowIds);
  }

  /// Null when the row with [rowId] at [index] appears without animation.
  RowEntrance? entranceFor(Object rowId, int index) {
    if (!_enteredRowIds.add(rowId)) return null;
    if (!_initialRowIds!.contains(rowId)) return const InsertedRowEntrance();
    if (_isInitialEntranceOver || index >= maximumStaggeredEntranceCount) return null;
    return StaggeredRowEntrance(AppDurations.entranceStaggerStep * index);
  }
}

/// Plays [entrance] once when first built; shows [child] as is when [entrance] is null or the
/// system asks for reduced motion.
class RowEntranceAnimation extends StatefulWidget {
  const RowEntranceAnimation({required this.entrance, required this.child, super.key});

  final RowEntrance? entrance;
  final Widget child;

  @override
  State<RowEntranceAnimation> createState() => _RowEntranceAnimationState();
}

class _RowEntranceAnimationState extends State<RowEntranceAnimation> with SingleTickerProviderStateMixin {
  /// Read once: later builds of the same row get no entrance, and the widget tree around the
  /// row must not change shape, or the row would lose its state.
  late final RowEntrance? _entrance = widget.entrance;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.entrance,
    value: _entrance == null ? 1 : 0,
  );
  late final Animation<double> _progress = CurvedAnimation(parent: _controller, curve: AppCurves.standard);
  Timer? _delayTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isCompleted || _controller.isAnimating || _delayTimer != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final delay = switch (_entrance) {
      StaggeredRowEntrance(:final delay) => delay,
      _ => Duration.zero,
    };
    _delayTimer = Timer(delay, () => unawaited(_controller.forward()));
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entrance == null) return widget.child;
    final risingChild = AnimatedBuilder(
      animation: _progress,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(offset: Offset(0, (1 - _progress.value) * entranceRiseDistance), child: child),
      ),
      child: widget.child,
    );
    return switch (_entrance) {
      InsertedRowEntrance() => SizeTransition(
        sizeFactor: _progress,
        alignment: Alignment.topCenter,
        child: risingChild,
      ),
      _ => risingChild,
    };
  }
}
