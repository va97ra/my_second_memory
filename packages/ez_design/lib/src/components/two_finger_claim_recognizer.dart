import 'package:flutter/gestures.dart';

/// Забирает касание, как только на месте лежат два пальца.
///
/// Сам ничего не сообщает: его дело — спор за касание. Пока палец один, он
/// молча ждёт и уступает и нажатию, и листанию. Опустился второй — он
/// объявляет оба пальца своими, и нажатие под ними уже не сработает, а
/// листание не начнётся. Если листание успело взять первый палец раньше,
/// спорить поздно: тогда жест различает тот, кто считает пальцы сам.
class TwoFingerClaimRecognizer extends GestureRecognizer {
  TwoFingerClaimRecognizer({super.debugOwner});

  final _entries = <int, GestureArenaEntry>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final pointer = event.pointer;
    GestureBinding.instance.pointerRouter.addRoute(pointer, _handleEvent);
    _entries[pointer] = GestureBinding.instance.gestureArena.add(pointer, this);
    if (_entries.length < 2) return;
    for (final entry in _entries.values.toList()) {
      entry.resolve(GestureDisposition.accepted);
    }
  }

  void _handleEvent(PointerEvent event) {
    if (event is! PointerUpEvent && event is! PointerCancelEvent) return;
    // Палец поднят, а второго так и не было: касание — чужое. Отказ до
    // подведения итогов, иначе спор достался бы первому записавшемуся.
    _entries[event.pointer]?.resolve(GestureDisposition.rejected);
    _stopTracking(event.pointer);
  }

  void _stopTracking(int pointer) {
    if (_entries.remove(pointer) == null) return;
    GestureBinding.instance.pointerRouter.removeRoute(pointer, _handleEvent);
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) => _stopTracking(pointer);

  @override
  void dispose() {
    for (final pointer in _entries.keys.toList()) {
      _entries[pointer]?.resolve(GestureDisposition.rejected);
      _stopTracking(pointer);
    }
    super.dispose();
  }

  @override
  String get debugDescription => 'two finger claim';
}
