import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/ui/widgets/record_editor_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('линейка едет вместе с текстом', (tester) async {
    final controller = TextEditingController(
      text: List.generate(60, (index) => 'строка $index').join('\n'),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNotebookTheme(),
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: RecordEditorField(controller: controller, onChanged: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lines = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<NotebookPaperLinesPainter>()
        .single;
    final atStart = lines.firstLine;
    expect(atStart, lines.top);

    lines.scroll!.jumpTo(lines.lineHeight / 2);
    await tester.pump();
    expect(lines.firstLine, closeTo(atStart - lines.lineHeight / 2, 0.01));

    // Сдвиг на целую строку: первая линия снова на том же месте относительно
    // края, а не уехала и не пропала.
    lines.scroll!.jumpTo(lines.lineHeight * 40);
    await tester.pump();
    expect(lines.firstLine, greaterThanOrEqualTo(0));
    expect(lines.firstLine, lessThanOrEqualTo(lines.lineHeight));
  });
}
