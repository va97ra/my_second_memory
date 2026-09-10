import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/theme_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Выбор оформления помещается на невысоком экране. Тем четыре, они стоят
/// сеткой два на два, и на телефоне 1080×1920 нижний ряд не влезал — лист
/// обрезал его без всякой возможности добраться.
void main() {
  testWidgets('the appearance sheet scrolls instead of clipping',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showThemePickerSheet(
                  context: context,
                  selected: AppThemeStyle.notebookLight,
                  isRu: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    // Последняя тема доступна: до неё можно долистать.
    await tester.scrollUntilVisible(find.text('Киберпанк'), 120);
    expect(find.text('Киберпанк'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
