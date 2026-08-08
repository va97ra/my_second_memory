import 'package:ezhednevnik_v2/src/core/theme/app_surface_textures.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_surface_palette.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_theme.dart';
import 'package:ezhednevnik_v2/src/core/theme/notebook/notebook_background.dart';
import 'package:ezhednevnik_v2/src/core/theme/notebook/notebook_visuals.dart';
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
