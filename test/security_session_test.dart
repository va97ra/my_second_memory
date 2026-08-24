import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _SessionSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => false;

  @override
  Future<AppCipher?> unlockWithPin(String pin) async {
    if (pin != '1234') return null;
    return AppCipher.fromPin(
      pin: pin,
      salt: List<int>.filled(16, 8),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lock clears only the in-memory unlock session', () async {
    final controller = SecuritySessionController(_SessionSecurityService());
    await controller.load();
    expect(await controller.unlockWithPin('1234'), isTrue);
    final firstCipher = controller.state.cipher!;

    controller.lock();

    expect(controller.state.setupCompleted, isTrue);
    expect(controller.state.hasPin, isTrue);
    expect(controller.state.biometricsEnabled, isFalse);
    expect(controller.state.isUnlocked, isFalse);
    expect(controller.state.cipher, isNull);
    expect(firstCipher.isDestroyed, isTrue);

    expect(await controller.unlockWithPin('1234'), isTrue);
    expect(controller.state.isUnlocked, isTrue);
    expect(controller.state.cipher, isNot(same(firstCipher)));
    controller.dispose();
  });

  test('wrong pin does not replace an unlocked session', () async {
    final controller = SecuritySessionController(_SessionSecurityService());
    await controller.load();
    await controller.unlockWithPin('1234');
    final cipher = controller.state.cipher!;

    expect(await controller.unlockWithPin('9999'), isFalse);

    expect(controller.state.isUnlocked, isTrue);
    expect(controller.state.cipher, same(cipher));
    expect(cipher.isDestroyed, isFalse);
    controller.dispose();
  });
}
