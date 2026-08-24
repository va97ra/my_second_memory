import 'dart:convert';

import '../security/app_cipher.dart';
import 'package:ez_domain/ez_domain.dart';

class CreatedSyncVault {
  const CreatedSyncVault({
    required this.profile,
    required this.cipher,
    required this.recoveryCode,
  });

  final SyncVaultProfile profile;
  final AppCipher cipher;
  final String recoveryCode;
}

class SyncVaultCrypto {
  const SyncVaultCrypto();

  static const _verifierText = 'ezhednevnik-sync-vault-v1';

  Future<CreatedSyncVault> create(String password) async {
    final salt = AppCipher.randomSalt();
    final masterKey = [...AppCipher.randomSalt(), ...AppCipher.randomSalt()];
    final wrappingCipher = await AppCipher.fromPin(pin: password, salt: salt);
    try {
      final wrappedKey = await wrappingCipher.encryptString(
        base64Encode(masterKey),
      );
      final cipher = AppCipher.fromKeyBytes(masterKey);
      final keyVerifier = await cipher.encryptString(_verifierText);
      return CreatedSyncVault(
        profile: SyncVaultProfile(
          salt: base64Encode(salt),
          wrappedKey: wrappedKey,
          keyVerifier: keyVerifier,
        ),
        cipher: cipher,
        recoveryCode: base64UrlEncode(masterKey).replaceAll('=', ''),
      );
    } finally {
      wrappingCipher.destroy();
      masterKey.fillRange(0, masterKey.length, 0);
    }
  }

  Future<AppCipher> unlock(SyncVaultProfile profile, String password) async {
    final wrappingCipher = await AppCipher.fromPin(
      pin: password,
      salt: base64Decode(profile.salt),
    );
    try {
      final encoded = await wrappingCipher.decryptString(profile.wrappedKey);
      final cipher = AppCipher.fromKeyBytes(base64Decode(encoded));
      await _verify(cipher, profile);
      return cipher;
    } on Object {
      throw const FormatException('Incorrect synchronization password');
    } finally {
      wrappingCipher.destroy();
    }
  }

  Future<AppCipher> unlockWithRecoveryCode(
    SyncVaultProfile profile,
    String recoveryCode,
  ) async {
    final normalized = recoveryCode.trim();
    final padding = '=' * ((4 - normalized.length % 4) % 4);
    final key = base64Url.decode('$normalized$padding');
    if (key.length != 32) {
      throw const FormatException('Invalid recovery code');
    }
    final cipher = AppCipher.fromKeyBytes(key);
    await _verify(cipher, profile);
    return cipher;
  }

  Future<void> _verify(AppCipher cipher, SyncVaultProfile profile) async {
    try {
      final value = await cipher.decryptString(profile.keyVerifier);
      if (value != _verifierText) throw const FormatException();
    } on Object {
      cipher.destroy();
      throw const FormatException('Invalid synchronization recovery code');
    }
  }
}
