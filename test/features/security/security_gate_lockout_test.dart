import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_gate_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/provider_test_support.dart';

/// Хранилище, в котором PIN всегда неверен, а ожидание назначает тест.
class _LockingSecurityService extends SecurityService {
  Duration? delay;
  int checks = 0;

  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => false;

  @override
  Future<Duration?> pinRetryDelay() async => delay;

  @override
  Future<AppCipher?> unlockWithPin(String pin) async {
    checks++;
    return null;
  }
}

void main() {
  late _LockingSecurityService service;
  late SecuritySessionController session;
  late SecurityGateController gate;

  setUp(() async {
    service = _LockingSecurityService();
    session = testContainer(
            overrides: [securityServiceProvider.overrideWithValue(service)])
        .read(securitySessionProvider.notifier);
    gate = SecurityGateController(session);
  });

  tearDown(() {
    gate.dispose();
  });

  testWidgets('после череды ошибок замок говорит, сколько ждать, и отсчитывает',
      (tester) async {
    await gate.load();
    await gate.unlockWithPin('0000');
    expect(gate.problem, SecurityGateProblem.wrongPin);
    expect(gate.retryAfter, isNull);

    service.delay = const Duration(seconds: 3);
    await gate.unlockWithPin('0000');
    expect(gate.problem, SecurityGateProblem.pinLocked);
    expect(gate.retryAfter, const Duration(seconds: 3));

    // Пока замок ждёт, PIN даже не уходит на проверку.
    final checks = service.checks;
    await gate.unlockWithPin('1234');
    expect(service.checks, checks);

    service.delay = null;
    await tester.pump(const Duration(seconds: 1));
    expect(gate.retryAfter, const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(gate.retryAfter, isNull);
    expect(gate.problem, isNull);
  });

  testWidgets('ожидание, начатое до перезапуска, видно сразу при открытии',
      (tester) async {
    service.delay = const Duration(seconds: 20);
    await gate.load();

    expect(gate.problem, SecurityGateProblem.pinLocked);
    expect(gate.retryAfter, const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
  });
}
