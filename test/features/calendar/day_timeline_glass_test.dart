import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Шкала дня лежит на пластине стекла. Без неё часовые линии и подписи
/// времени рисуются прямо на заднике и пропадают в нём — на городской улице
/// киберпанка особенно.
void main() {
  testWidgets('the day scale sits on a glass plate in screen themes',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        theme: buildScreenTheme(cyberpunkColors),
        home: Scaffold(
          body: DayTimeline(items: const [], onCreate: (_, __) {}),
        ),
        ),
      ),
    );
    await tester.pump();

    final plates = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((box) => (box.decoration as BoxDecoration).gradient != null);
    expect(plates, isNotEmpty, reason: 'пластины под шкалой нет');
  });

  testWidgets('the plate survives inside the real day screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildScreenTheme(cyberpunkColors),
          home: Scaffold(
            body: Column(
              children: [
                // Так шкала стоит на экране дня: в `Expanded`, под шапкой и
                // полосой смен. Изолированный виджет пластину показывал, а на
                // устройстве её не было — проверяем в той же обвязке.
                Expanded(
                  child: DayTimeline(items: const [], onCreate: (_, __) {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final plates = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((box) => (box.decoration as BoxDecoration).gradient != null);
    expect(plates, isNotEmpty, reason: 'пластины под шкалой нет');
  });
}
