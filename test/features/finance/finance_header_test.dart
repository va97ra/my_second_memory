import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/finance/ui/widgets/finance_month_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  // Перенос строки — не исключение, поэтому проверка «нет переполнения» его
  // пропускала: кнопка конвертера спокойно уезжала на вторую строку и висела
  // там одна. Здесь проверяется то, что видно глазом: валюта и конвертер
  // стоят на одной высоте, то есть шапка осталась одной строкой.
  for (final width in [320.0, 360.0, 411.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
          'the finance header keeps its size at ${width}px and ${scale}x',
          (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.binding.setSurfaceSize(Size(width, 900));
        await _pump(tester);

        expect(tester.takeException(), isNull);
        final card = tester.getRect(
          find.byKey(const ValueKey('finance_header_card')),
        );
        expect(card.height, moreOrLessEquals(notebookHeaderHeight, epsilon: 2));
        for (final key in ['finance_currency', 'finance_converter']) {
          expect(
            card.contains(tester.getCenter(find.byKey(ValueKey(key)))),
            isTrue,
            reason: key,
          );
        }
      });
    }
  }
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    testProviderScope(
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: FinanceMonthHeader(
            currency: 'RUB',
            month: DateTime(2026, 9),
            onCurrency: (_) {},
            onMonthDelta: (_) {},
            onConverter: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
