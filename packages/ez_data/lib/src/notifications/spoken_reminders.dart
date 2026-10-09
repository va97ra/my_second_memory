import 'package:ez_domain/ez_domain.dart' show JarvisTone;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// Что сказать вслух и когда: [id] — тот же, что у уведомления.
typedef SpokenReminder = ({int id, DateTime at, String text});

/// Голос Джарвиса в момент напоминания — даже когда приложение закрыто.
///
/// Уведомление показывает flutter_local_notifications, а голос ставит свой
/// будильник Android на то же время (`SpokenReminders.kt`): говорить из
/// закрытого приложения Flutter не умеет. Телефон молчит в беззвучном
/// режиме, при «Не беспокоить» и во время звонка. Не Android — ничего не
/// делает.
///
/// Напоминания разложены по группам — источникам уведомлений: группу
/// всегда пересылают целиком, и лишнее в ней снимается.
class SpokenReminders {
  const SpokenReminders();

  static const _channel = MethodChannel('ezhednevnik_v2/speak');

  bool get _supported =>
      !_isFlutterTest &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  /// Голосом, тоном и темпом Джарвиса.
  static Map<String, Object?> get _tone => {
        'voices': JarvisTone.voices,
        'pitch': JarvisTone.pitch,
        'rate': JarvisTone.rate,
      };

  Future<void> _call(String method, Map<String, Object?> arguments) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method, {..._tone, ...arguments});
    } on MissingPluginException {
      // Сборка без своего Android-кода: голоса нет, уведомления остаются.
    }
  }

  static Map<String, Object?> _encode(SpokenReminder reminder) => {
        'id': reminder.id,
        'at': reminder.at.millisecondsSinceEpoch,
        'text': reminder.text,
      };

  /// Группа целиком: остальные её напоминания снимаются.
  Future<void> sync(String group, Iterable<SpokenReminder> reminders) =>
      _call('sync', {
        'group': group,
        'items': [for (final reminder in reminders) _encode(reminder)],
      });

  /// Одно напоминание группы — поставить или переставить.
  Future<void> put(String group, SpokenReminder reminder) =>
      _call('put', {'group': group, ..._encode(reminder)});

  Future<void> remove(int id) => _call('remove', {'id': id});

  /// Говорить ли вслух. Выключено — напоминания стоят, но молчат.
  Future<void> setEnabled(bool enabled) =>
      _call('setEnabled', {'enabled': enabled});
}
