import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Сколько раз можно ошибиться в PIN подряд и сколько потом ждать.
///
/// Пять ошибок ничего не стоят: палец промахивается. После пятой замок ждёт
/// [firstDelay], и каждая следующая ошибка удваивает ожидание до [maxDelay].
/// Счёт лежит в защищённом хранилище рядом с самим PIN: перезапуск
/// приложения ожидание не снимает. Верный PIN обнуляет счёт.
class PinAttemptLimit {
  PinAttemptLimit(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const freeAttempts = 5;
  static const firstDelay = Duration(seconds: 30);
  static const maxDelay = Duration(minutes: 30);

  static const _failuresKey = 'pin_failed_attempts_v1';
  static const _lockedUntilKey = 'pin_locked_until_v1';
  static const _lockLengthKey = 'pin_lock_length_v1';

  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;

  /// Сколько ещё ждать до следующей попытки; `null` — пробовать можно.
  ///
  /// Ожидание не бывает длиннее назначенного: часы, переведённые назад, не
  /// запирают замок на месяц.
  Future<Duration?> remaining() async {
    final until = int.tryParse(await _storage.read(key: _lockedUntilKey) ?? '');
    final length = int.tryParse(await _storage.read(key: _lockLengthKey) ?? '');
    if (until == null || length == null) return null;
    final left = until - _clock().millisecondsSinceEpoch;
    if (left <= 0) return null;
    return Duration(milliseconds: math.min(left, length));
  }

  /// Ещё одна ошибка: после пятой назначается ожидание.
  Future<void> recordFailure() async {
    final failures =
        (int.tryParse(await _storage.read(key: _failuresKey) ?? '') ?? 0) + 1;
    await _storage.write(key: _failuresKey, value: '$failures');
    final delay = delayAfter(failures);
    if (delay == Duration.zero) return;
    final until = _clock().add(delay).millisecondsSinceEpoch;
    await _storage.write(key: _lockedUntilKey, value: '$until');
    await _storage.write(key: _lockLengthKey, value: '${delay.inMilliseconds}');
  }

  Future<void> reset() async {
    await _storage.delete(key: _failuresKey);
    await _storage.delete(key: _lockedUntilKey);
    await _storage.delete(key: _lockLengthKey);
  }

  /// Ожидание после [failures] ошибок подряд.
  static Duration delayAfter(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    final doublings = math.min(failures - freeAttempts, 16);
    final delay = firstDelay * (1 << doublings);
    return delay > maxDelay ? maxDelay : delay;
  }
}
