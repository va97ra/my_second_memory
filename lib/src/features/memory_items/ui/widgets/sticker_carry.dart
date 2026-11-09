import 'package:flutter/widgets.dart';

/// Что сейчас происходит с несомой карточкой. Заводит тот, кто показывает, куда
/// её можно донести; карточка сообщает сюда, где палец.
class StickerCarry {
  /// Палец сдвинулся меньше — значит, карточку не несли, а только приподняли.
  static const slop = 12.0;

  /// Где палец. Пусто, пока карточку только приподняли.
  final pointer = ValueNotifier<Offset?>(null);

  /// Палец над шкалой дней: список под ней стоит, а карточка не заслоняет шкалу.
  final overRail = ValueNotifier<bool>(false);

  DateTime? _day;
  Offset? _liftedAt;
  bool _disposed = false;

  /// День записи, которую несут.
  DateTime? get day => _day;

  /// Где палец оказался, когда карточку приподняли.
  Offset? get liftedAt => _liftedAt;

  void begin(DateTime day) {
    _day = day;
    _liftedAt = null;
  }

  void move(Offset at) {
    final lifted = _liftedAt ??= at;
    if (pointer.value != null || (at - lifted).distance >= slop) {
      pointer.value = at;
    }
  }

  void end() {
    if (_disposed) return;
    overRail.value = false;
    pointer.value = null;
  }

  void dispose() {
    _disposed = true;
    pointer.dispose();
    overRail.dispose();
  }
}
