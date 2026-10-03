import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Подпись разделителя в поиске — это дата, ради которой искали. На узком
  // экране с крупным шрифтом она теряла хвост: «Вторник, 15 сентябр…» — без
  // года.
  for (final scale in [1.3, 2.0]) {
    testWidgets('a long label wraps instead of losing its tail at x$scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const label = 'Вторник, 15 сентября 2026 г.';

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 480),
              textScaler: TextScaler.linear(scale),
            ),
            child: const Scaffold(
              body: AppLabeledDivider(
                label: label,
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
