import 'package:ez_data/ez_data.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/finance_controller.dart';
import 'package:ezhednevnik_v2/src/features/finance/ui/widgets/finance_category_field.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('finance journals are isolated by currency and editable',
      (tester) async {
    addTearDown(tester.view.resetViewInsets);
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, 10);
    final repository = _FinanceRepository([
      _entry(
        'rub-opening',
        FinanceEntryKind.income,
        '1000',
        'RUB',
        DateTime(now.year, now.month - 1, 10),
        'Начальный остаток',
      ),
      _entry('rub-income', FinanceEntryKind.income, '100', 'RUB', date,
          'Зарплата'),
      _entry('rub-expense', FinanceEntryKind.expense, '25.5', 'RUB', date,
          'Моя категория'),
      _entry('usd-income', FinanceEntryKind.income, '40', 'USD', date,
          'Freelance'),
    ]);
    await _openFinance(tester, const Size(360, 800), repository);

    expect(find.text('100 RUB'), findsOneWidget);
    expect(find.text('25.5 RUB'), findsOneWidget);
    expect(find.text('1074.5 RUB'), findsOneWidget);
    expect(find.text('Моя категория'), findsOneWidget);
    expect(find.text('Начальный остаток'), findsNothing);
    expect(find.text('Freelance'), findsNothing);

    final summary = find.byKey(const ValueKey('finance_summary_card'));
    final incomeButton = find.byKey(const ValueKey('finance_add_income'));
    final expenseButton = find.byKey(const ValueKey('finance_add_expense'));
    expect(
      find.descendant(
        of: summary,
        matching: find.text('Доходы и расходы'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(summary).dx,
      closeTo(tester.getTopLeft(incomeButton).dx, 0.1),
    );
    expect(
      tester.getTopRight(summary).dx,
      closeTo(tester.getTopRight(expenseButton).dx, 0.1),
    );
    expect(
      tester
          .getCenter(find.byKey(const ValueKey('finance_entry_rub-income')))
          .dx,
      lessThan(
        tester
            .getCenter(
              find.byKey(const ValueKey('finance_entry_rub-expense')),
            )
            .dx,
      ),
    );
    final financeViewportHeight = tester
        .getSize(find.byKey(const ValueKey('finance_scroll')))
        .height;

    await tester.tap(incomeButton);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('finance_scroll'))).height,
      financeViewportHeight,
    );
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('finance_amount')),
      '0.1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('finance_category')),
      'Новый источник',
    );
    await _tapSave(tester);
    expect(find.text('Новый источник'), findsOneWidget);
    expect(repository.entries.any((entry) => entry.amount == '0.1'), isTrue);

    final tile = find
        .ancestor(
          of: find.text('Новый источник'),
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('finance_amount')), '0.2');
    await _tapSave(tester);
    expect(repository.entries.any((entry) => entry.amount == '0.2'), isTrue);

    final editedTile = find
        .ancestor(
          of: find.text('Новый источник'),
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(find.descendant(
      of: editedTile,
      matching: find.byIcon(Icons.delete_outline_rounded),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Новый источник'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('finance_currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    expect(find.text('40 USD'), findsWidgets);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Моя категория'), findsNothing);
  });

  testWidgets('category suggestions stay readable in the light theme',
      (tester) async {
    final theme = buildNotebookTheme(brightness: Brightness.light);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: FinanceCategoryField(
            initialValue: '',
            categories: const ['Зарплата', 'Аванс'],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('finance_category')));
    await tester.pumpAndSettle();

    final surface = tester.widget<Material>(
      find.byKey(const ValueKey('finance_category_options')),
    );
    final option = tester.widget<Text>(find.text('Зарплата'));
    expect(surface.color, theme.colorScheme.surface);
    expect(option.style?.color, theme.colorScheme.onSurface);
  });

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('finance has no overflow at ${width}px and ${scale}x',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final now = DateTime.now();
        final repository = _FinanceRepository([
          _entry(
            'long',
            FinanceEntryKind.expense,
            '1234567890.123456789',
            'RUB',
            DateTime(now.year, now.month, 1),
            'Очень длинная пользовательская категория',
          ),
        ]);
        await _openFinance(tester, Size(width, 720), repository);
        final category = tester.widget<Text>(
          find.text('Очень длинная пользовательская категория'),
        );
        expect(category.maxLines, isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _tapSave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final save = find.widgetWithText(FilledButton, 'Сохранить');
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> _openFinance(
  WidgetTester tester,
  Size size,
  FinanceRepository repository,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        memoryRepositoryProvider.overrideWithValue(EmptyMemoryRepository()),
        shiftScheduleRepositoryProvider.overrideWithValue(
          FakeShiftScheduleRepository(),
        ),
        financeRepositoryProvider.overrideWithValue(repository),
      ],
      child: const EzhednevnikV2App(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('top_finance')));
  await tester.pumpAndSettle();
}

class _FinanceRepository implements FinanceRepository {
  _FinanceRepository(this.entries);
  List<FinanceEntry> entries;

  @override
  Future<List<FinanceEntry>> loadAll() async => List.of(entries);

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    this.entries = List.of(entries);
  }
}

FinanceEntry _entry(
  String id,
  FinanceEntryKind kind,
  String amount,
  String currency,
  DateTime date,
  String category,
) {
  return FinanceEntry(
    id: id,
    kind: kind,
    amount: amount,
    currencyCode: currency,
    category: category,
    occurredOn: date,
    createdAt: date,
    updatedAt: date,
  );
}
