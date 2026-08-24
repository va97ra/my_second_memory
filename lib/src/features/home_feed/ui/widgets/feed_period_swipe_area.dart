import 'package:flutter/material.dart';

/// Листание периода пальцем поверх страницы ленты.
///
/// Считает не только рывок, но и медленное перетаскивание: страницу тянут за
/// край так же часто, как смахивают.
class FeedPeriodSwipeArea extends StatefulWidget {
  const FeedPeriodSwipeArea({
    super.key,
    required this.onMovePeriod,
    required this.child,
  });

  final ValueChanged<int> onMovePeriod;
  final Widget child;

  @override
  State<FeedPeriodSwipeArea> createState() => _FeedPeriodSwipeAreaState();
}

class _FeedPeriodSwipeAreaState extends State<FeedPeriodSwipeArea> {
  static const _distanceThreshold = 48.0;
  static const _velocityThreshold = 350.0;

  double _dragExtent = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('feed_period_swipe_area'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragExtent = 0,
      onHorizontalDragUpdate: (details) {
        _dragExtent += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: _finish,
      onHorizontalDragCancel: () => _dragExtent = 0,
      child: widget.child,
    );
  }

  void _finish(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _dragExtent;
    _dragExtent = 0;

    // Утянутый влево лист переваливает через корешок: это следующая страница.
    if (distance.abs() >= _distanceThreshold) {
      widget.onMovePeriod(distance < 0 ? 1 : -1);
      return;
    }
    if (velocity.abs() >= _velocityThreshold) {
      widget.onMovePeriod(velocity < 0 ? 1 : -1);
    }
  }
}
