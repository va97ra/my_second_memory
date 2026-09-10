import 'package:ezhednevnik_v2/src/shared/ui/page_hint_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Подсказка страницы лежит в кнопке, а не на экране: пока её не спросили,
/// места она не занимает. Выключенная настройка убирает и саму кнопку.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(String hint) => ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          home: Scaffold(body: Center(child: PageHintButton(hint: hint))),
        ),
      );

  const hint = 'Записи собраны по дням. Стрелки листают период.';

  testWidgets('the hint stays inside the button until it is asked for',
      (tester) async {
    await tester.pumpWidget(host(hint));

    expect(find.text(hint), findsNothing);

    await tester.tap(find.byKey(const ValueKey('page_hint_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('page_hint_text')), findsOneWidget);
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('a second press puts the hint away', (tester) async {
    await tester.pumpWidget(host(hint));

    await tester.tap(find.byKey(const ValueKey('page_hint_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('page_hint_button')));
    await tester.pumpAndSettle();

    expect(find.text(hint), findsNothing);
  });

  testWidgets('the switched-off setting takes the button out of the layout',
      (tester) async {
    SharedPreferences.setMockInitialValues({'calendar_hints_enabled_v1': false});
    await tester.pumpWidget(host(hint));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('page_hint_button')), findsNothing);
    expect(tester.getSize(find.byType(PageHintButton)), Size.zero);
  });
}
