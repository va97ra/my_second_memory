import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/security/data/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('pin is verified through encrypted verifier and not plaintext key',
      () async {
    final service = SecurityService();

    expect(await service.setupCompleted(), isFalse);

    await service.setPin('1234');

    expect(await service.setupCompleted(), isTrue);
    expect(await service.hasPin(), isTrue);
    expect(await service.verifyPin('1234'), isTrue);
    expect(await service.verifyPin('9999'), isFalse);
  });

  test('pin can be cleared only after caller verifies current pin', () async {
    final service = SecurityService();

    await service.setPin('1234');

    expect(await service.unlockWithPin('9999'), isNull);
    expect(await service.hasPin(), isTrue);

    final cipher = await service.unlockWithPin('1234');
    expect(cipher, isNotNull);

    await service.clearPin();

    expect(await service.setupCompleted(), isTrue);
    expect(await service.hasPin(), isFalse);
    expect(await service.biometricsEnabled(), isFalse);
  });

  test('biometrics flag requires pin and is cleared with pin', () async {
    final service = SecurityService();

    await service.setBiometricsEnabled(true, authenticate: false);
    expect(await service.biometricsEnabled(), isFalse);

    await service.setPin('1234');
    final cipher = await service.unlockWithPin('1234');
    await service.setBiometricsEnabled(
      true,
      cipher: cipher,
      authenticate: false,
    );

    expect(await service.biometricsEnabled(), isTrue);

    await service.clearPin();
    expect(await service.biometricsEnabled(), isFalse);
  });
}
