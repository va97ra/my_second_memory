import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/converter/converter.dart';
import 'package:ezhednevnik_v2/src/features/engineering/engineering.dart';
import 'package:ezhednevnik_v2/src/features/electrician/electrician.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('new tools fit acceptance widths and text scales',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final width in [320.0, 360.0, 600.0, 840.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        for (final screen in const <Widget>[
          ConverterScreen(),
          EngineeringScreen(),
          ElectricianScreen(),
        ]) {
          await tester.pumpWidget(
            testProviderScope(child: MaterialApp(home: screen)),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$screen at $width px and ${scale}x text',
          );
        }
      }
    }
  });
}
