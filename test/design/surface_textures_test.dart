import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _darkCardStandsOutOnLeather();

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

  testWidgets('notebook app background is the page leather', (tester) async {
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

    expect(image.assetName, NotebookAssets.lightPage);
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

/// Средний тон снимка чёрной кожи (`black_leather.webp`, 13 из 255): им
/// просвечивает текстура сквозь цвет поверхности.
const _blackLeatherMean = Color(0xFF0D0D0D);

/// Цвет, которым поверхность на коже видна глазу: кожа тонируется её цветом
/// на 55 %, как в [NotebookLeatherSurface].
Color _seenOnLeather(Color surface) =>
    Color.alphaBlend(surface.withValues(alpha: 0.55), _blackLeatherMean);

void _darkCardStandsOutOnLeather() {
  test('на чёрной коже карточка заметно светлее страницы и темнее диалога', () {
    final colors = buildNotebookTheme(brightness: Brightness.dark).colorScheme;
    final page = _seenOnLeather(AppPalette.black);
    final card = _seenOnLeather(colors.surface);

    expect(_contrast(card, page), greaterThanOrEqualTo(1.2));
    expect(card.computeLuminance(),
        lessThan(AppPalette.blackDialog.computeLuminance()));
  });
}
