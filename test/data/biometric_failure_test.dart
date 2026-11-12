import 'package:ez_data/ez_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

/// Датчик есть и настроен, но отказывает исключением — так Android отвечает,
/// когда датчик заблокирован после пяти неудачных попыток.
class _LockedOutSensor extends LocalAuthentication {
  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> get canCheckBiometrics async => true;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      const [BiometricType.fingerprint];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object?> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    throw PlatformException(code: 'LockedOut');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('a locked out sensor is a refusal, not a crash', () async {
    final service = SecurityService(localAuthentication: _LockedOutSensor());

    expect(await service.authenticateWithBiometrics(), isFalse);
  });

  test('unlocking with a locked out sensor gives no key', () async {
    final service = SecurityService(localAuthentication: _LockedOutSensor());
    await service.setPin('1234');
    await service.setBiometricsEnabled(
      true,
      cipher: await service.unlockWithPin('1234'),
      authenticate: false,
    );

    expect(await service.unlockWithBiometrics(), isNull);
  });
}
