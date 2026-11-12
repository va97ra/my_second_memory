import 'dart:async';

import 'package:flutter/foundation.dart';

import 'security_provider.dart';

/// Что помешало открыть замок.
enum SecurityGateProblem { wrongPin, pinLocked, biometricsUnavailable }

/// Состояние замка приложения: чем сейчас занят и что не получилось.
///
/// Сам PIN сюда не попадает дальше вызова: он приходит из поля ввода, уходит
/// в сессию и не сохраняется.
class SecurityGateController extends ChangeNotifier {
  SecurityGateController(this._session);

  final SecuritySessionController _session;

  bool isLoading = true;
  bool showPinFallback = false;
  bool biometricBusy = false;
  bool pinUnlockBusy = false;
  bool setupBusy = false;
  bool offerBiometrics = false;
  SecurityGateProblem? problem;
  String? startupError;

  /// Сколько ещё ждать до следующей попытки PIN после череды ошибок; `null` —
  /// пробовать можно. Отсчитывается здесь же, раз в секунду.
  Duration? retryAfter;
  Timer? _retryTimer;

  bool _biometricAttempted = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Биометрию спрашивают один раз за показ карточки: иначе системный запрос
  /// открывался бы заново на каждом кадре.
  bool takeBiometricAttempt() {
    if (_biometricAttempted || biometricBusy) return false;
    _biometricAttempted = true;
    return true;
  }

  /// Переход между двумя способами открыть замок.
  void switchTo({required bool pinFallback}) {
    showPinFallback = pinFallback;
    if (!pinFallback) _biometricAttempted = false;
    problem = null;
    _notify();
  }

  /// Открывает защищённое хранилище. Оно может не ответить, поэтому ожидание
  /// ограничено: без этого приложение не показало бы вообще ничего.
  Future<void> load() async {
    isLoading = true;
    startupError = null;
    _notify();
    try {
      await _session.load().timeout(const Duration(seconds: 8));
      // Ожидание, начатое до перезапуска, продолжается: его видно сразу.
      // Без PIN ждать нечего.
      if (_session.hasPin) await _refreshRetryDelay();
    } on Object catch (error) {
      startupError = error.toString();
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> createInitialPin(String pin) async {
    if (pin.isEmpty) {
      problem = SecurityGateProblem.wrongPin;
      _notify();
      return;
    }

    setupBusy = true;
    problem = null;
    _notify();
    try {
      await _session.setPin(pin);
      offerBiometrics = true;
    } finally {
      setupBusy = false;
      _notify();
    }
  }

  /// Включает биометрию. Возвращает false, если устройство её не даёт.
  Future<bool> enableInitialBiometrics() async {
    biometricBusy = true;
    _notify();
    try {
      return await _session.setBiometricsEnabled(true);
    } finally {
      biometricBusy = false;
      offerBiometrics = false;
      _notify();
    }
  }

  Future<void> unlockWithPin(String pin) async {
    if (pinUnlockBusy || retryAfter != null) return;
    if (pin.isEmpty) {
      problem = SecurityGateProblem.wrongPin;
      _notify();
      return;
    }

    pinUnlockBusy = true;
    problem = null;
    _notify();
    try {
      final ok = await _session.unlockWithPin(pin);
      problem = ok ? null : SecurityGateProblem.wrongPin;
      if (!ok) await _refreshRetryDelay();
    } finally {
      pinUnlockBusy = false;
      _notify();
    }
  }

  Future<void> unlockWithBiometrics() async {
    biometricBusy = true;
    problem = null;
    _notify();
    var ok = false;
    try {
      ok = await _session.unlockWithBiometrics();
    } finally {
      // Занятость снимается при любом исходе: иначе после ошибки кнопки замка
      // молчали бы до перезапуска.
      biometricBusy = false;
      problem = ok ? null : SecurityGateProblem.biometricsUnavailable;
      _notify();
    }
  }

  /// Спрашивает у хранилища, ждёт ли замок, и запускает отсчёт.
  Future<void> _refreshRetryDelay() async {
    final delay = await _session.pinRetryDelay();
    _retryTimer?.cancel();
    retryAfter = delay;
    if (delay == null) return;
    problem = SecurityGateProblem.pinLocked;
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (retryAfter ?? Duration.zero) - const Duration(seconds: 1);
      if (left > Duration.zero) {
        retryAfter = left;
      } else {
        timer.cancel();
        retryAfter = null;
        if (problem == SecurityGateProblem.pinLocked) problem = null;
      }
      _notify();
    });
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
