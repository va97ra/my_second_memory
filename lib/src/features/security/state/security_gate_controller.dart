import 'package:flutter/foundation.dart';

import 'security_provider.dart';

/// Что помешало открыть замок.
enum SecurityGateProblem { wrongPin, biometricsUnavailable }

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

  bool _biometricAttempted = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
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

    await _session.setPin(pin);
    setupBusy = false;
    offerBiometrics = true;
    _notify();
  }

  /// Включает биометрию. Возвращает false, если устройство её не даёт.
  Future<bool> enableInitialBiometrics() async {
    biometricBusy = true;
    _notify();

    final ok = await _session.setBiometricsEnabled(true);
    biometricBusy = false;
    offerBiometrics = false;
    _notify();
    return ok;
  }

  Future<void> unlockWithPin(String pin) async {
    if (pinUnlockBusy) return;
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
    } finally {
      pinUnlockBusy = false;
      _notify();
    }
  }

  Future<void> unlockWithBiometrics() async {
    biometricBusy = true;
    problem = null;
    _notify();

    final ok = await _session.unlockWithBiometrics();
    biometricBusy = false;
    problem = ok ? null : SecurityGateProblem.biometricsUnavailable;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
