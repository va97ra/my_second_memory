part of '../widget_test.dart';

void registerSecurityWidgetTests() {
  testWidgets('first launch requires pin setup', (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_FreshSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
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
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
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
