import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'app_cipher.dart';

class SecurityService {
  SecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuthentication = localAuthentication ?? LocalAuthentication();

  static const _pinKey = 'app_pin_v1';
  static const _pinHashKey = 'app_pin_hash_v2';
  static const _pinSaltKey = 'app_pin_salt_v2';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuthentication;

  Future<bool> hasPin() async {
    return (await _storage.read(key: _pinHashKey)) != null ||
        (await _storage.read(key: _pinKey)) != null;
  }

  Future<void> setPin(String pin) async {
    final salt = AppCipher.randomSalt();
    final cipher = await AppCipher.fromPin(pin: pin, salt: salt);
    final verifier = await cipher.encryptString('pin-ok');
    await _storage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _storage.write(key: _pinHashKey, value: verifier);
    await _storage.delete(key: _pinKey);
  }

  Future<bool> verifyPin(String pin) async {
    return (await unlockWithPin(pin)) != null;
  }

  Future<AppCipher?> unlockWithPin(String pin) async {
    final legacyPin = await _storage.read(key: _pinKey);
    if (legacyPin != null) {
      if (legacyPin != pin) {
        return null;
      }
      await setPin(pin);
    }

    final saltRaw = await _storage.read(key: _pinSaltKey);
    final verifier = await _storage.read(key: _pinHashKey);
    if (saltRaw == null || verifier == null) {
      return null;
    }

    final cipher = await AppCipher.fromPin(
      pin: pin,
      salt: base64Decode(saltRaw),
    );
    try {
      final value = await cipher.decryptString(verifier);
      return value == 'pin-ok' ? cipher : null;
    } catch (_) {
      return null;
    }
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
