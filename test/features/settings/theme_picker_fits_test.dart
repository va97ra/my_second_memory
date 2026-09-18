import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/theme_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Все включённые темы доступны на невысоком экране.
void main() {
  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('three themes fit width $width, scale $scale',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
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
        await tester.scrollUntilVisible(find.text('Космос'), 120);
        expect(find.text('Космос'), findsOneWidget);
        expect(find.text('Киберпанк'), findsNothing);
        expect(AppThemeStyle.available, [
          AppThemeStyle.notebookLight,
          AppThemeStyle.notebookDark,
          AppThemeStyle.cosmos
        ]);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
