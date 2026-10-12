import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/content_font_picker_sheet.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/font_preview_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Шрифтов стало полтора десятка: окно выбора обязано листаться, иначе
/// нижние шрифты не выбрать (замечено владельцем 12 октября 2026).
void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('до последнего шрифта можно долистать при $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AppContentFontStyle? chosen;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 640),
            textScaler: TextScaler.linear(scale),
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    chosen = await showContentFontPickerSheet(
                  context: context,
                  selected: AppContentFontStyle.values.first,
                  isRu: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final last = find.byWidgetPredicate((widget) =>
          widget is FontPreviewRow &&
          widget.style == AppContentFontStyle.values.last);
      await tester.scrollUntilVisible(last, 120,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(chosen, AppContentFontStyle.values.last);
      expect(tester.takeException(), isNull);
    });
  }
}
