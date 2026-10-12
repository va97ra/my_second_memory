import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/ui/widgets/text_color_picker.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/ui/widgets/text_format_panel.dart';
import 'package:ezhednevnik_v2/src/shared/ui/styled_text_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Панель оформления: выделил — нажал — сохранилось с оформлением.
void main() {
  Future<StyledTextController> open(WidgetTester tester) async {
    final controller = StyledTextController()..load('Купить хлеб и молоко');
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller, maxLines: null),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => controller.hasSelection
                  ? TextFormatPanel(controller: controller)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ));
    return controller;
  }

  testWidgets('панель — только пока текст выделен', (tester) async {
    final controller = await open(tester);
    expect(find.byKey(const ValueKey('text_format_panel')), findsNothing);
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 11);
    await tester.pump();
    expect(find.byKey(const ValueKey('text_format_panel')), findsOneWidget);
  });

  testWidgets('жирный и цвет ложатся на выделенное и сохраняются',
      (tester) async {
    final controller = await open(tester);
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 11);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('format_bold')));
    await tester.pump();
    expect(controller.current.bold, isTrue);
    await tester.tap(find.byKey(const ValueKey('format_color')));
    await tester.pumpAndSettle();
    // Ползунок оттенка — на треть: зелёный; цвет ложится сразу, без «ОК».
    final hue = find.byKey(const ValueKey('format_hue'));
    final box = tester.getRect(hue);
    await tester
        .tapAt(Offset(box.left + 14 + (box.width - 28) / 3, box.center.dy));
    await tester.pump();
    final green = textColorOf(120, 0.85);
    var stored = StyledText.parse(controller.stored);
    final run = stored.runs().single;
    expect(stored.plain.substring(run.start, run.end), 'хлеб');
    expect(run.mark, TextMark(bold: true, color: green));

    // Насыщенность до упора влево — серый того же оттенка.
    final saturation =
        tester.getRect(find.byKey(const ValueKey('format_saturation')));
    await tester.tapAt(Offset(saturation.left + 1, saturation.center.dy));
    await tester.pump();
    stored = StyledText.parse(controller.stored);
    expect(stored.runs().single.mark.color, textColorOf(120, 0));

    // «Как у записи» — цвет снят, жирный остался.
    await tester.tap(find.byKey(const ValueKey('format_color_default')));
    await tester.pump();
    stored = StyledText.parse(controller.stored);
    expect(stored.runs().single.mark, const TextMark(bold: true));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(controller.text, 'Купить хлеб и молоко',
        reason: 'в поле — чистый текст, оформление поверх');

    // Второе нажатие снимает жирный.
    await tester.tap(find.byKey(const ValueKey('format_bold')));
    await tester.pump();
    expect(controller.current.bold, isFalse);
  });

  testWidgets('шрифт — из общего списка шрифтов', (tester) async {
    final controller = await open(tester);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('format_font')));
    await tester.pumpAndSettle();
    // Шрифтов много — до нужного листают.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('format_font_lora')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('format_font_lora')));
    await tester.pumpAndSettle();
    expect(StyledText.parse(controller.stored).runs().single.mark.font, 'lora');
  });
}
