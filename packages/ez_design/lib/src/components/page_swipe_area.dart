import 'package:flutter/material.dart';

import 'two_finger_claim_recognizer.dart';

/// Листание страницы пальцем и, по желанию, щипок двумя.
///
/// Считает не только рывок, но и медленное перетаскивание: страницу тянут за
/// край так же часто, как смахивают. Обработчику приходит `1` для движения
/// влево или вверх — это следующая страница — и `-1` для обратного.
///
/// Щипок включается обработчиками [onPinchUpdate] и [onPinchEnd]: им приходит
/// отношение расстояния между пальцами к начальному — меньше единицы, когда
/// пальцы сводят, больше — когда разводят. Жест, в котором побывали два
/// пальца, страницу не листает, даже если первый палец уже начал её тянуть.
class PageSwipeArea extends StatefulWidget {
  const PageSwipeArea({
    super.key,
    this.onHorizontalSwipe,
    this.onVerticalSwipe,
    this.onPinchUpdate,
    this.onPinchEnd,
    required this.child,
  });

  final ValueChanged<int>? onHorizontalSwipe;
  final ValueChanged<int>? onVerticalSwipe;
  final ValueChanged<double>? onPinchUpdate;
  final ValueChanged<double>? onPinchEnd;
  final Widget child;

  @override
  State<PageSwipeArea> createState() => _PageSwipeAreaState();
}

class _PageSwipeAreaState extends State<PageSwipeArea> {
  static const _distanceThreshold = 48.0;
  static const _velocityThreshold = 350.0;

  double _horizontalExtent = 0;
  double _verticalExtent = 0;

  /// Пальцы на странице и где они сейчас.
  final _pointers = <int, Offset>{};

  /// Расстояние между двумя пальцами в начале щипка; `null` — щипка нет.
  double? _pinchStartSpan;
  double _pinchScale = 1;

  /// В этом касании побывали два пальца. Сбрасывается, когда опускается
  /// первый палец следующего касания: конец листания приходит уже после того,
  /// как последний палец поднят.
  bool _wasMultiTouch = false;

  bool get _pinchEnabled =>
      widget.onPinchUpdate != null || widget.onPinchEnd != null;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.onHorizontalSwipe;
    final vertical = widget.onVerticalSwipe;

    Widget area = GestureDetector(
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
    if (!_pinchEnabled) return area;

    area = RawGestureDetector(
      gestures: {
        TwoFingerClaimRecognizer:
            GestureRecognizerFactoryWithHandlers<TwoFingerClaimRecognizer>(
          () => TwoFingerClaimRecognizer(debugOwner: this),
          (_) {},
        ),
      },
      child: area,
    );
    return Listener(
      onPointerDown: _pointerDown,
      onPointerMove: _pointerMove,
      onPointerUp: _pointerGone,
      onPointerCancel: _pointerGone,
      child: area,
    );
  }

  void _pointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) _wasMultiTouch = false;
    _pointers[event.pointer] = event.position;
    if (_pointers.length != 2) return;
    _wasMultiTouch = true;
    _pinchStartSpan = _span();
    _pinchScale = 1;
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    final startSpan = _pinchStartSpan;
    if (startSpan == null || _pointers.length != 2 || startSpan == 0) return;
    _pinchScale = _span() / startSpan;
    widget.onPinchUpdate?.call(_pinchScale);
  }

  void _pointerGone(PointerEvent event) {
    if (_pointers.remove(event.pointer) == null) return;
    if (_pinchStartSpan == null) return;
    _pinchStartSpan = null;
    widget.onPinchEnd?.call(_pinchScale);
  }

  /// Расстояние между первыми двумя пальцами: третий щипок не меняет.
  double _span() {
    final positions = _pointers.values.take(2).toList();
    return (positions[0] - positions[1]).distance;
  }

  void _finish(DragEndDetails details, double extent, ValueChanged<int> emit) {
    final velocity = details.primaryVelocity ?? 0;
    _horizontalExtent = 0;
    _verticalExtent = 0;
    if (_pinchEnabled && _wasMultiTouch) return;

    if (extent.abs() >= _distanceThreshold) {
      emit(extent < 0 ? 1 : -1);
      return;
    }
    if (velocity.abs() >= _velocityThreshold) {
      emit(velocity < 0 ? 1 : -1);
    }
  }
}
