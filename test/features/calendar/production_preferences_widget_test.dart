import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/production_preferences.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/production_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();
  testWidgets(
      'preferences fit supported widths and text scales; switches update state',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 360.0, 600.0, 840.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.binding.setSurfaceSize(Size(width, 740));
        await tester.pumpWidget(testProviderScope(
            child: MaterialApp(
          theme: buildNotebookTheme(brightness: Brightness.light),
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: const ProductionPreferencesScreen(),
        )));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
            tester.element(find.byType(ProductionPreferencesScreen)));
        final before = container.read(productionPreferencesProvider).highlight;
        await tester
            .tap(find.byKey(const ValueKey('production_highlight_setting')));
        await tester.pumpAndSettle();
        expect(
            container.read(productionPreferencesProvider).highlight, !before);
        expect(tester.takeException(), isNull,
            reason: 'width $width scale $scale');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
