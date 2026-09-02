import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_data/ez_data.dart';
import '../../../app/local_storage_scope_provider.dart';

final securityServiceProvider = Provider<SecurityService>(
  (ref) => SecurityService(),
);

final securityDataMigrationServiceProvider =
    Provider<SecurityDataMigrationService>((ref) {
  return SecurityDataMigrationService(ref.watch(localStorageScopeProvider));
});

final securitySessionProvider =
    StateNotifierProvider<SecuritySessionController, SecuritySessionState>(
  (ref) => SecuritySessionController(ref.watch(securityServiceProvider)),
);

class SecuritySessionState {
  const SecuritySessionState({
    this.setupCompleted = false,
    this.hasPin = false,
    this.isUnlocked = false,
    this.biometricsEnabled = false,
    this.cipher,
  });

  final bool setupCompleted;
  final bool hasPin;
  final bool isUnlocked;
  final bool biometricsEnabled;
  final AppCipher? cipher;

  /// Доступны ли зашифрованные данные прямо сейчас.
  ///
  /// PIN не задан — скрывать нечего, доступ открыт; задан — только после
  /// разблокировки. Это правило одно на всё приложение: по нему пускает
  /// экран-замок и по нему же решает, можно ли синхронизироваться.
  bool get canReadData => !hasPin || isUnlocked;

  SecuritySessionState copyWith({
    bool? setupCompleted,
    bool? hasPin,
    bool? isUnlocked,
    bool? biometricsEnabled,
    AppCipher? cipher,
    bool clearCipher = false,
  }) {
    return SecuritySessionState(
      setupCompleted: setupCompleted ?? this.setupCompleted,
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
    final setupCompleted = await _service.setupCompleted();
    state = state.copyWith(
      setupCompleted: setupCompleted,
      hasPin: hasPin,
      biometricsEnabled: hasPin ? await _service.biometricsEnabled() : false,
    );
  }

  Future<bool> unlockWithPin(String pin) async {
    final cipher = await _service.unlockWithPin(pin);
    if (cipher == null) {
      return false;
    }
    _replaceState(SecuritySessionState(
      setupCompleted: true,
      hasPin: true,
      isUnlocked: true,
      biometricsEnabled: await _service.biometricsEnabled(),
      cipher: cipher,
    ));
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
    final ok =
        await _service.setBiometricsEnabled(enabled, cipher: state.cipher);
    state = state.copyWith(
      biometricsEnabled: await _service.biometricsEnabled(),
    );
    return ok && state.biometricsEnabled == enabled;
  }

  Future<void> clearPinSession() async {
    await _service.clearPin();
    _replaceState(const SecuritySessionState());
    await load();
  }

  void lock() {
    if (!state.isUnlocked && state.cipher == null) return;
    _replaceState(
      state.copyWith(
        isUnlocked: false,
        clearCipher: true,
      ),
    );
  }

  Future<bool> unlockWithBiometrics() async {
    final cipher = await _service.unlockWithBiometrics();
    if (cipher == null) {
      return false;
    }
    _replaceState(SecuritySessionState(
      setupCompleted: true,
      hasPin: true,
      isUnlocked: true,
      biometricsEnabled: true,
      cipher: cipher,
    ));
    return true;
  }

  void _replaceState(SecuritySessionState next) {
    final previousCipher = state.cipher;
    state = next;
    if (!identical(previousCipher, next.cipher)) {
      previousCipher?.destroy();
    }
  }

  @override
  void dispose() {
    state.cipher?.destroy();
    super.dispose();
  }
}
