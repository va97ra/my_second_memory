import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  SecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const _pinKey = 'app_pin_v1';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuthentication;

  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinKey)) != null;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final saved = await _storage.read(key: _pinKey);
    return saved == pin;
  }

  Future<bool> authenticateWithBiometrics() async {
    final canCheck = await _localAuthentication.canCheckBiometrics;
    if (!canCheck) {
      return false;
    }
    return _localAuthentication.authenticate(
      localizedReason: 'Unlock your memory',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }
}
