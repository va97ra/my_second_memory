import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('first launch requires pin setup', (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_FreshSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Создайте PIN для защиты данных'), findsOneWidget);
    expect(find.text('Создать PIN'), findsOneWidget);
    expect(find.text('Лента дня'), findsNothing);
  });

  testWidgets('secure storage timeout shows a retry screen', (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_HangingSecurityService()),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(
      find.text('Не удалось запустить защищённое хранилище'),
      findsOneWidget,
    );
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Лента дня'), findsNothing);
  });

  testWidgets('biometric unlock hides pin until fallback is requested',
      (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(
            _BiometricFailsSecurityService(),
          ),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Войти по PIN'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'PIN'), findsNothing);

    await tester.tap(find.text('Войти по PIN'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
  });

  testWidgets('pin field is cleared after a failed unlock attempt',
      (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(
            _PinRejectingSecurityService(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    final pinField = find.widgetWithText(TextField, 'PIN');
    tester.widget<TextField>(pinField).controller?.text = '1234';
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный PIN'), findsOneWidget);
    expect(tester.widget<TextField>(pinField).controller?.text, isEmpty);
  });

  testWidgets('startup submits one pin check even after a repeated tap',
      (tester) async {
    final security = _CountingPinSecurityService();
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(security),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    final pinField = find.widgetWithText(TextField, 'PIN');
    expect(pinField, findsOneWidget);
    await tester.enterText(pinField, '1234');
    final unlockButton = find.widgetWithText(FilledButton, 'Открыть');
    await tester.tap(unlockButton);
    await tester.tap(unlockButton);

    expect(security.unlockAttempts, 1);
    security.unlockCompleter.complete(null);
    await tester.pumpAndSettle();
  });
}

class _FreshSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => false;

  @override
  Future<bool> hasPin() async => false;
}

class _BiometricFailsSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => true;

  @override
  Future<AppCipher?> unlockWithBiometrics() async => null;
}

class _PinRejectingSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => false;

  @override
  Future<AppCipher?> unlockWithPin(String pin) async => null;
}

class _CountingPinSecurityService extends SecurityService {
  final unlockCompleter = Completer<AppCipher?>();
  int unlockAttempts = 0;

  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => false;

  @override
  Future<AppCipher?> unlockWithPin(String pin) {
    unlockAttempts++;
    return unlockCompleter.future;
  }
}

class _HangingSecurityService extends SecurityService {
  @override
  Future<bool> hasPin() => Completer<bool>().future;
}
