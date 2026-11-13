import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_gate_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/provider_test_support.dart';

/// Хранилище ключей, которое отказывает на любом шаге. Ошибка доходит до
/// замка, и замок не должен остаться «занятым» навсегда: иначе кнопки
/// биометрии и PIN больше не нажимаются до перезапуска.
class _FailingSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => true;

  @override
  Future<AppCipher?> unlockWithPin(String pin) =>
      AppCipher.fromPin(pin: pin, salt: List<int>.filled(16, 3));

  @override
  Future<AppCipher?> unlockWithBiometrics() =>
      Future.error(StateError('secure storage is unavailable'));

  @override
  Future<void> setPin(String pin) =>
      Future.error(StateError('secure storage is unavailable'));

  @override
  Future<bool> setBiometricsEnabled(
    bool enabled, {
    AppCipher? cipher,
    bool authenticate = true,
  }) =>
      Future.error(StateError('secure storage is unavailable'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecuritySessionController session;
  late SecurityGateController gate;

  setUp(() async {
    session = testContainer(overrides: [
      securityServiceProvider.overrideWithValue(_FailingSecurityService())
    ]).read(securitySessionProvider.notifier);
    await session.load();
    gate = SecurityGateController(session);
  });

  tearDown(() {
    gate.dispose();
  });

  test('a failed biometric unlock frees the lock and says why', () async {
    await expectLater(gate.unlockWithBiometrics(), throwsStateError);

    expect(gate.biometricBusy, isFalse);
    expect(gate.problem, SecurityGateProblem.biometricsUnavailable);
  });

  test('a failed first PIN does not leave setup busy', () async {
    await expectLater(gate.createInitialPin('1234'), throwsStateError);

    expect(gate.setupBusy, isFalse);
  });

  test('failing to turn on biometrics does not leave the lock busy', () async {
    await session.unlockWithPin('1234');

    await expectLater(gate.enableInitialBiometrics(), throwsStateError);

    expect(gate.biometricBusy, isFalse);
  });
}
