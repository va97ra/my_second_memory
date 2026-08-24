import 'package:flutter/material.dart';

/// Листание страницы пальцем.
///
/// Считает не только рывок, но и медленное перетаскивание: страницу тянут за
/// край так же часто, как смахивают. Обработчику приходит `1` для движения
/// влево или вверх — это следующая страница — и `-1` для обратного.
class PageSwipeArea extends StatefulWidget {
  const PageSwipeArea({
    super.key,
    this.onHorizontalSwipe,
    this.onVerticalSwipe,
    required this.child,
  });

  final ValueChanged<int>? onHorizontalSwipe;
  final ValueChanged<int>? onVerticalSwipe;
  final Widget child;

  @override
  State<PageSwipeArea> createState() => _PageSwipeAreaState();
}

class _PageSwipeAreaState extends State<PageSwipeArea> {
  static const _distanceThreshold = 48.0;
  static const _velocityThreshold = 350.0;

  double _horizontalExtent = 0;
  double _verticalExtent = 0;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.onHorizontalSwipe;
    final vertical = widget.onVerticalSwipe;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart:
          horizontal == null ? null : (_) => _horizontalExtent = 0,
      onHorizontalDragUpdate: horizontal == null
          ? null
          : (details) => _horizontalExtent += details.primaryDelta ?? 0,
      onHorizontalDragEnd: horizontal == null
          ? null
          : (details) => _finish(details, _horizontalExtent, horizontal),
      onHorizontalDragCancel:
          horizontal == null ? null : () => _horizontalExtent = 0,
      onVerticalDragStart: vertical == null ? null : (_) => _verticalExtent = 0,
      onVerticalDragUpdate: vertical == null
          ? null
          : (details) => _verticalExtent += details.primaryDelta ?? 0,
      onVerticalDragEnd: vertical == null
          ? null
          : (details) => _finish(details, _verticalExtent, vertical),
      onVerticalDragCancel: vertical == null ? null : () => _verticalExtent = 0,
      child: widget.child,
    );
  }

  void _finish(DragEndDetails details, double extent, ValueChanged<int> emit) {
    final velocity = details.primaryVelocity ?? 0;
    _horizontalExtent = 0;
    _verticalExtent = 0;

    if (extent.abs() >= _distanceThreshold) {
      emit(extent < 0 ? 1 : -1);
      return;
    }
    if (velocity.abs() >= _velocityThreshold) {
      emit(velocity < 0 ? 1 : -1);
    }
  }
}
