import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cyberpunk uses the city street backdrop', (tester) async {
    await tester.pumpWidget(
      const ScreenBackdrop(
        colors: cyberpunkColors,
        child: SizedBox.expand(),
      ),
    );
    await tester.pumpAndSettle();

    final backdrop = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = backdrop.decoration as BoxDecoration;
    final image = decoration.image!.image as AssetImage;
    expect(image.assetName, 'assets/textures/cyberpunk_city_street.webp');
    expect(tester.takeException(), isNull);
  });

  test('only cyberpunk glass carries street-light reflections', () {
    expect(cyberpunkColors.glassLights, hasLength(3));
    expect(cosmosColors.glassLights, isEmpty);

    final cyberpunkGradient = GlassSurface.gradient(
      cyberpunkColors,
      cyberpunkColors.tile,
    );
    final cosmosGradient = GlassSurface.gradient(
      cosmosColors,
      cosmosColors.tile,
    );
    expect(cyberpunkGradient.colors, hasLength(7));
    expect(cosmosGradient.colors, hasLength(4));
  });

  testWidgets('thick cyberpunk glass receives the reflection palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 240,
          height: 80,
          child: ScreenGlassSurface(
            colors: cyberpunkColors,
            opacity: 0.5,
            painterKey: ValueKey('glass_painter'),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('glass_painter')),
    );
    expect(
      paint.foregroundPainter.runtimeType.toString(),
      'ScreenGlassSurfacePainter',
    );
    expect(tester.takeException(), isNull);
  });
}
