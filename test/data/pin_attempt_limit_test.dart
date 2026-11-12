import 'package:ez_data/ez_data.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  SecurityService service() => SecurityService(clock: () => now);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    now = DateTime(2026, 11, 12, 20);
  });

  Future<void> fail(SecurityService security, int times) async {
    for (var attempt = 0; attempt < times; attempt++) {
      expect(await security.unlockWithPin('0000'), isNull);
    }
  }

  test('пять ошибок подряд ничего не стоят', () async {
    final security = service();
    await security.setPin('1234');

    await fail(security, PinAttemptLimit.freeAttempts - 1);
    expect(await security.pinRetryDelay(), isNull);
    expect(await security.verifyPin('1234'), isTrue);
  });

  test('после пятой ошибки замок ждёт, и верный PIN тоже не проходит',
      () async {
    final security = service();
    await security.setPin('1234');

    await fail(security, PinAttemptLimit.freeAttempts);
    expect(await security.pinRetryDelay(), PinAttemptLimit.firstDelay);
    expect(await security.unlockWithPin('1234'), isNull);

    now = now.add(PinAttemptLimit.firstDelay);
    expect(await security.pinRetryDelay(), isNull);
    final cipher = await security.unlockWithPin('1234');
    expect(cipher, isNotNull);
    cipher!.destroy();
  });

  test('каждая следующая ошибка удваивает ожидание, но не дольше потолка',
      () async {
    final security = service();
    await security.setPin('1234');
    await fail(security, PinAttemptLimit.freeAttempts);

    var expected = PinAttemptLimit.firstDelay;
    for (var round = 0; round < 10; round++) {
      now = now.add(expected);
      await fail(security, 1);
      expected = expected * 2 > PinAttemptLimit.maxDelay
          ? PinAttemptLimit.maxDelay
          : expected * 2;
      expect(await security.pinRetryDelay(), expected, reason: 'круг $round');
    }
  });

  test('ожидание переживает перезапуск приложения', () async {
    await service().setPin('1234');
    await fail(service(), PinAttemptLimit.freeAttempts);

    now = now.add(const Duration(seconds: 10));
    expect(
      await service().pinRetryDelay(),
      PinAttemptLimit.firstDelay - const Duration(seconds: 10),
    );
  });

  test('верный PIN обнуляет счёт ошибок', () async {
    final security = service();
    await security.setPin('1234');

    await fail(security, PinAttemptLimit.freeAttempts - 1);
    expect(await security.verifyPin('1234'), isTrue);
    await fail(security, PinAttemptLimit.freeAttempts - 1);
    expect(await security.pinRetryDelay(), isNull);
  });

  test('часы, переведённые назад, не растягивают ожидание сверх потолка',
      () async {
    final security = service();
    await security.setPin('1234');
    await fail(security, PinAttemptLimit.freeAttempts);

    now = now.subtract(const Duration(days: 30));
    expect(await security.pinRetryDelay(), PinAttemptLimit.firstDelay);
  });

  test('снятый PIN снимает и ожидание', () async {
    final security = service();
    await security.setPin('1234');
    await fail(security, PinAttemptLimit.freeAttempts);

    await security.clearPin();
    expect(await security.pinRetryDelay(), isNull);
  });
}
