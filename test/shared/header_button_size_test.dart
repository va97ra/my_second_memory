import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/shared/ui/chrome/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Клавиши шапки одного роста. Ряд из кнопок разного размера рассыпается, и
/// это видно раньше, чем прочитан заголовок.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('every icon button in a page header is the same size',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          home: Scaffold(
            appBar: AppPageAppBar(
              title: const Text('Заголовок'),
              fallbackLocation: '/calendar',
              hint: 'Что здесь можно сделать.',
              actions: [
                IconButton(
                  key: const ValueKey('action'),
                  onPressed: () {},
                  icon: const Icon(Icons.settings_rounded, size: 22),
                  style: notebookIconButtonStyle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sizes = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .map((button) => tester.getSize(find.byWidget(button)))
        .toSet();

    expect(sizes.length, 1, reason: 'разные размеры: $sizes');

    // И стоят они по слотам одной ширины: ряд читается сеткой, а не набором
    // кнопок, прижатых к краям.
    final slots = tester
        .widgetList<SizedBox>(find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(SizedBox),
        ))
        .where((box) => box.width == notebookHeaderSlot)
        .length;
    expect(slots, greaterThanOrEqualTo(3), reason: 'назад, подсказка, действие');
  });
}
