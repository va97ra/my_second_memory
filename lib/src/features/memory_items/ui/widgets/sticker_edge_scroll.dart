import 'dart:async';

import 'package:flutter/widgets.dart';

/// Прокручивает список, пока листок несут у его верхнего или нижнего края:
/// иначе на день, которого не видно на экране, не перенести.
class StickerEdgeScroll {
  static const _edge = 72.0;
  static const _maxStep = 14.0;
  static const _tick = Duration(milliseconds: 16);

  Timer? _timer;
  double _step = 0;
  ScrollPosition? _position;

  void update(BuildContext context, Offset pointer) {
    final scrollable = Scrollable.maybeOf(context);
    final box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    _position = scrollable.position;
    _step = pointer.dy < top + _edge
        ? -_maxStep * ((top + _edge - pointer.dy) / _edge).clamp(0.0, 1.0)
        : pointer.dy > bottom - _edge
            ? _maxStep * ((pointer.dy - bottom + _edge) / _edge).clamp(0.0, 1.0)
            : 0;
    if (_step == 0) {
      stop();
    } else {
      _timer ??= Timer.periodic(_tick, (_) => _scroll());
    }
  }

  void _scroll() {
    final position = _position;
    if (position == null || !position.hasPixels) return stop();
    position.jumpTo(
      (position.pixels + _step).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
