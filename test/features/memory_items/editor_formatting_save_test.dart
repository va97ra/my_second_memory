import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:ezhednevnik_v2/src/shared/ui/styled_text_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

/// Оформление — такая же правка, как набор: выделил, нажал «жирный», закрыл
/// — запись сохранена жирной. Раньше сохранение запускал только набор, и
/// оформление пропадало (отзыв владельца 11 октября 2026).
void main() {
  testWidgets('жирный без набора сохраняется', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FeedMemoryRepository();
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('record_editor_text'));
    await tester.enterText(field, 'Купить хлеб');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final text = tester.widget<TextField>(
      find.descendant(of: field, matching: find.byType(TextField)).first,
    );
    final controller = text.controller! as StyledTextController;
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 11);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('format_bold')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final note = repository.savedItems
        .singleWhere((item) => item.plainBody == 'Купить хлеб');
    final saved = StyledText.parse(note.body);
    expect(saved.plain, 'Купить хлеб');
    final bold = saved.runs().single;
    expect(saved.plain.substring(bold.start, bold.end), 'хлеб');
    expect(bold.mark.bold, isTrue);
  });
}
