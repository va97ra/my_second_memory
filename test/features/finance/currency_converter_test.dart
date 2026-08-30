import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/exchange_rate_controller.dart';
import 'package:ezhednevnik_v2/src/features/finance/ui/widgets/currency_converter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

final _rates = ExchangeRates(
  base: 'RUB',
  date: DateTime(2026, 8, 30),
  basePerUnit: const {'USD': 90.0, 'EUR': 100.0},
);

void main() {
  useTestEnvironment();

  testWidgets('the converter answers in the target currency and names the date',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await _open(tester);

    expect(find.byKey(const ValueKey('converter_result')), findsOneWidget);
    expect(find.text('11.11 USD'), findsOneWidget);
    expect(find.textContaining('30 августа 2026'), findsOneWidget);
  });

  testWidgets('swapping the pair converts the other way', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('converter_swap')));
    await tester.pumpAndSettle();

    expect(find.text('90000.00 RUB'), findsOneWidget);
  });

  testWidgets('the converter fits the acceptance widths and text scales',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final width in [320.0, 360.0, 600.0, 840.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await _open(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'converter at $width px and ${scale}x text',
        );
      }
    }
  });
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    testProviderScope(
      overrides: [
        exchangeRatesProvider.overrideWith((ref) async => _rates),
      ],
      child: const MaterialApp(
        locale: Locale('ru'),
        supportedLocales: [Locale('ru'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: CurrencyConverterSheet(initialFrom: 'RUB'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
