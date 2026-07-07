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
    this.cipher,
  });

  final bool hasPin;
  final bool isUnlocked;
  final AppCipher? cipher;

  SecuritySessionState copyWith({
    bool? hasPin,
    bool? isUnlocked,
    AppCipher? cipher,
  }) {
    return SecuritySessionState(
      hasPin: hasPin ?? this.hasPin,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      cipher: cipher ?? this.cipher,
    );
  }
}

class SecuritySessionController extends StateNotifier<SecuritySessionState> {
  SecuritySessionController(this._service)
      : super(const SecuritySessionState());

  final SecurityService _service;

  Future<void> load() async {
    state = state.copyWith(hasPin: await _service.hasPin());
  }

  Future<bool> unlockWithPin(String pin) async {
    final cipher = await _service.unlockWithPin(pin);
    if (cipher == null) {
      return false;
    }
    state = SecuritySessionState(
      hasPin: true,
      isUnlocked: true,
      cipher: cipher,
    );
    return true;
  }

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    await unlockWithPin(pin);
  }

  Future<bool> unlockWithBiometrics() async {
    if (state.hasPin) {
      return false;
    }
    final ok = await _service.authenticateWithBiometrics();
    if (ok) {
      state = state.copyWith(isUnlocked: true);
    }
    return ok;
  }
}
