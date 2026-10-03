import 'dart:async';
import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_calendar_provider.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/production_day_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/production_calendar_test_support.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();
  testWidgets(
      'network year updates day and dialog; refresh failure preserves totals',
      (tester) async {
    final pending = Completer<String>();
    var fail = false;
    final repository = ProductionCalendarRepository(
        source: FakeProductionSource((_) =>
            fail ? Future.error(StateError('offline')) : pending.future));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        productionCalendarRepositoryProvider.overrideWithValue(repository)
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: ProductionDayStatus(date: DateTime(2025, 1, 1))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Статистика работы'), findsOneWidget);
    // Synthetic response for testing propagation, not a historical calendar.
    pending.complete('1${'0' * 364}');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Нормы и источник'));
    await tester.tap(find.text('Нормы и источник'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Рабочих дней: 30'), findsOneWidget);
    expect(find.textContaining('Источник: isDayOff.ru'), findsOneWidget);
    expect(find.textContaining('Обновлено:'), findsOneWidget);
    fail = true;
    await tester.ensureVisible(find.text('Обновить'));
    await tester.tap(find.text('Обновить'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Не удалось получить обновление'), findsOneWidget);
    expect(find.textContaining('Рабочих дней: 30'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
