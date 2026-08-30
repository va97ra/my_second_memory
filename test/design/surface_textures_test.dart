import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark theme exposes textures without notebook behavior', () {
    final theme = buildAppTheme(brightness: Brightness.dark);

    expect(theme.extension<AppSurfaceTextures>(), AppSurfaceTextures.dark);
    expect(theme.extension<NotebookVisuals>(), isNull);
  });

  test('light theme exposes its generated texture set', () {
    final theme = buildAppTheme(brightness: Brightness.light);

    expect(theme.extension<AppSurfaceTextures>(), AppSurfaceTextures.light);
  });

  test('app palettes use layered gradients and readable surface contrast', () {
    for (final brightness in Brightness.values) {
      final theme = buildAppTheme(brightness: brightness);
      final palette = theme.extension<AppSurfacePalette>()!;

      expect(palette.accentGradient.colors, hasLength(3));
      expect(palette.surfaceGradient().colors, hasLength(3));
      expect(
        _contrast(theme.colorScheme.onSurface, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('dark app background paints the generated wood texture',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.dark),
        home: const AppBackground(child: SizedBox.expand()),
      ),
    );

    final background = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = background.decoration as BoxDecoration;
    final image = decoration.image!.image as AssetImage;

    expect(image.assetName, DarkThemeAssets.wood);
  });

  testWidgets('light app background paints the generated wood texture',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light),
        home: const AppBackground(child: SizedBox.expand()),
      ),
    );

    final background = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = background.decoration as BoxDecoration;
    final image = decoration.image!.image as AssetImage;

    expect(image.assetName, LightThemeAssets.wood);
  });

  testWidgets('notebook app background is a ruled paper sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNotebookTheme(),
        home: const AppBackground(child: SizedBox.expand()),
      ),
    );

    final background = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = background.decoration as BoxDecoration;
    final image = decoration.image!.image as AssetImage;
    final lines = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<NotebookPaperLinesPainter>()
        .single;

    expect(image.assetName, NotebookAssets.paper);
    expect(
        lines.color,
        NotebookVisuals.maybeOf(
          tester.element(find.byType(AppBackground)),
        )!
            .line);
    expect(lines.top, notebookPageLineTop);
    expect(lines.lineHeight, notebookPageLineHeight);
  });

  testWidgets('notebook leather keeps its opaque fallback in the texture layer',
      (tester) async {
    const fallback = Color(0xFF31271F);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNotebookTheme(),
        home: const NotebookLeatherSurface(
          color: fallback,
          child: SizedBox(width: 200, height: 120),
        ),
      ),
    );

    final texturedDecoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .singleWhere((decoration) => decoration.image != null);

    // Цвет и изображение обязаны принадлежать одному слою. Если цвет лежит
    // отдельным виджетом ниже, при перевыделении текстурного слоя композитор
    // на кадр показывает навигационный градиент под панелью.
    expect(texturedDecoration.color, fallback);
  });

  testWidgets('dark paper surfaces paint ruled lines when requested',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.dark),
        home: const Scaffold(
          body: NotebookCardSurface(
            showLines: true,
            child: SizedBox(width: 200, height: 120),
          ),
        ),
      ),
    );

    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final lines = paints
        .map((paint) => paint.painter)
        .whereType<NotebookPaperLinesPainter>()
        .single;

    expect(lines.color, AppSurfaceTextures.dark.lineColor);
  });
}

double _contrast(Color first, Color second) {
  final high = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final low = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (high + 0.05) / (low + 0.05);
}
