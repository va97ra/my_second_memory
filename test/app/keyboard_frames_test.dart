import 'package:ez_data/ez_data.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/finance_controller.dart';
import 'package:ezhednevnik_v2/src/features/finance/ui/widgets/finance_amount_field.dart';
import 'package:ezhednevnik_v2/src/features/finance/ui/widgets/finance_category_field.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  // Клавиатура выезжает не рывком, а десятком кадров, и на каждом кадре у неё
  // новая высота. Кто эту высоту читает, тот на каждом кадре пересобирается:
  // пока её читала оболочка и тело листа, вместе с ними заново собирались обе
  // панели, фон и все поля ввода — отсюда и рывки при выезде.
  testWidgets('the keyboard slides without rebuilding the shell or the fields',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(EmptyMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
          financeRepositoryProvider.overrideWithValue(_EmptyFinanceRepository()),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('top_finance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_add_income')));
    await tester.pumpAndSettle();

    final rebuilt = await _widgetsRebuiltWhileKeyboardSlides(tester);

    expect(rebuilt, isNot(contains('AppNavBar')));
    expect(rebuilt, isNot(contains('AppToolBar')));
    expect(rebuilt, isNot(contains('$FinanceAmountField')));
    expect(rebuilt, isNot(contains('$FinanceCategoryField')));
    expect(rebuilt, isNot(contains('$AppBackground')));
  });
}

/// Прогоняет клавиатуру снизу вверх кадр за кадром и возвращает имена всех
/// виджетов, которые за это время собрались заново.
Future<Set<String>> _widgetsRebuiltWhileKeyboardSlides(
  WidgetTester tester,
) async {
  final names = <String>{};
  final previousPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null || !message.startsWith('Building ')) return;
    names.add(message.substring('Building '.length).split('(').first);
  };
  debugPrintRebuildDirtyWidgets = true;

  for (var step = 1; step <= 10; step++) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: 30.0 * step * tester.view.devicePixelRatio,
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  debugPrintRebuildDirtyWidgets = false;
  debugPrint = previousPrint;
  return names;
}

class _EmptyFinanceRepository implements FinanceRepository {
  @override
  Future<List<FinanceEntry>> loadAll() async => const [];

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {}
}
