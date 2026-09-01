import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/exchange_rate_controller.dart';
import 'package:ezhednevnik_v2/src/features/finance/ui/widgets/currency_converter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/widget_test_harness.dart';

ExchangeRates _ratesOn(DateTime date, {double usd = 90.0}) => ExchangeRates(
      base: 'RUB',
      date: date,
      basePerUnit: {'USD': usd, 'EUR': 100.0},
    );

final _rates = _ratesOn(DateTime(2026, 8, 30));

/// Источник, который считает походы за курсом и умеет публиковать новый.
class _FakeSource implements ExchangeRateSource {
  _FakeSource(this.rates);

  ExchangeRates rates;
  int fetches = 0;

  @override
  Future<ExchangeRates> fetch() async {
    fetches++;
    return rates;
  }
}

void main() {
  useTestEnvironment();

  group('лист конвертера', () {
    testWidgets('открывается на «сколько стоит доллар»', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await _open(tester);

      expect(find.byKey(const ValueKey('converter_result')), findsOneWidget);
      expect(find.text('90.00 RUB'), findsOneWidget);
      expect(find.textContaining('30 августа 2026'), findsOneWidget);
    });

    testWidgets('swapping the pair converts the other way', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await _open(tester);

      await tester.tap(find.byKey(const ValueKey('converter_swap')));
      await tester.pumpAndSettle();

      expect(find.text('0.01 USD'), findsOneWidget);
    });

    testWidgets('кнопка рядом с суммой идёт к источнику заново',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(360, 800));
      final source = _FakeSource(_rates);
      await _open(tester, source: source);
      expect(source.fetches, 1);

      source.rates = _ratesOn(DateTime(2026, 8, 31), usd: 100);
      await tester.tap(find.byKey(const ValueKey('converter_sync')));
      await tester.pumpAndSettle();

      expect(source.fetches, 2);
      expect(find.text('100.00 RUB'), findsOneWidget);
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
  });

  group('кэш курсов', () {
    test('свежий кэш бережёт источник, а «синхронизировать» — нет', () async {
      SharedPreferences.setMockInitialValues({});
      final today = DateTime.now();
      final source = _FakeSource(_ratesOn(today));
      final repository = ExchangeRateRepository(source: source);

      await repository.load();
      expect(source.fetches, 1, reason: 'кэша не было — сходили в сеть');
      await repository.load();
      expect(source.fetches, 1, reason: 'сегодняшний курс уже лежит');

      await repository.load(force: true);
      expect(source.fetches, 2, reason: 'человек попросил сходить заново');
    });
  });
}

Future<void> _open(WidgetTester tester, {_FakeSource? source}) async {
  await tester.pumpWidget(
    testProviderScope(
      overrides: [
        exchangeRateRepositoryProvider.overrideWith(
          (ref) =>
              ExchangeRateRepository(source: source ?? _FakeSource(_rates)),
        ),
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
            child: CurrencyConverterSheet(ledgerCurrency: 'RUB'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
