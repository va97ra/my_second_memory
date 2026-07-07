import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_cipher.dart';
import '../data/security_service.dart';

final securityServiceProvider = Provider<SecurityService>(
  (ref) => SecurityService(),
);

final securitySessionProvider =
    StateNotifierProvider<SecuritySessionController, SecuritySessionState>(
  (ref) => SecuritySessionController(ref.watch(securityServiceProvider)),
);

class SecuritySessionState {
  const SecuritySessionState({
    this.hasPin = false,
    this.isUnlocked = false,
    this.biometricsEnabled = false,
    this.cipher,
  });

  final bool hasPin;
  final bool isUnlocked;
  final bool biometricsEnabled;
  final AppCipher? cipher;

  SecuritySessionState copyWith({
    bool? hasPin,
    bool? isUnlocked,
    bool? biometricsEnabled,
    AppCipher? cipher,
    bool clearCipher = false,
  }) {
    return SecuritySessionState(
      hasPin: hasPin ?? this.hasPin,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      cipher: clearCipher ? null : cipher ?? this.cipher,
    );
  }
}

class SecuritySessionController extends StateNotifier<SecuritySessionState> {
  SecuritySessionController(this._service)
      : super(const SecuritySessionState());

  final SecurityService _service;

  Future<void> load() async {
    final hasPin = await _service.hasPin();
    state = state.copyWith(
      hasPin: hasPin,
      biometricsEnabled: hasPin ? await _service.biometricsEnabled() : false,
    );
  }

  Future<bool> unlockWithPin(String pin) async {
    final cipher = await _service.unlockWithPin(pin);
    if (cipher == null) {
      return false;
    }
    state = SecuritySessionState(
      hasPin: true,
      isUnlocked: true,
      biometricsEnabled: await _service.biometricsEnabled(),
      cipher: cipher,
    );
    return true;
  }

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    await unlockWithPin(pin);
  }

  Future<bool> setBiometricsEnabled(bool enabled) async {
    if (enabled && (!state.hasPin || state.cipher == null)) {
      return false;
    }
    await _service.setBiometricsEnabled(enabled, cipher: state.cipher);
    state = state.copyWith(
      biometricsEnabled: await _service.biometricsEnabled(),
    );
    return state.biometricsEnabled == enabled;
  }

  Future<void> clearPinSession() async {
    await _service.clearPin();
    state = const SecuritySessionState();
  }

  Future<bool> unlockWithBiometrics() async {
    final cipher = await _service.unlockWithBiometrics();
    if (cipher == null) {
      return false;
    }
    state = SecuritySessionState(
      hasPin: true,
      isUnlocked: true,
      biometricsEnabled: true,
      cipher: cipher,
    );
    return true;
  }
}
