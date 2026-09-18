import 'dart:io';
import 'dart:ui' as ui;

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_day_cell.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/day_number.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/production_calendar_dialog.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();
  testWidgets('production marks coexist with shifts and alarms at all sizes',
      (tester) async {
    final boundaryKey = GlobalKey();
    if (const bool.fromEnvironment('CAPTURE_PRODUCTION')) {
      await tester.runAsync(() async {
        final loader = FontLoader('Manrope')
          ..addFont(
              rootBundle.load('assets/fonts/Manrope-VariableFont_wght.ttf'));
        await loader.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final theme in AppThemeStyle.values) {
      for (final width in [320.0, 360.0, 600.0, 840.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          await tester.binding.setSurfaceSize(Size(width, 720));
          await tester.pumpWidget(testProviderScope(
              child: MaterialApp(
            theme: theme.isNotebook
                ? buildNotebookTheme(
                    brightness: theme == AppThemeStyle.notebookDark
                        ? Brightness.dark
                        : Brightness.light)
                : buildScreenTheme(screenColorsOf(theme)!),
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
                body: RepaintBoundary(
              key: boundaryKey,
              child: Column(children: [
                SizedBox(
                    height: 140,
                    child: Row(children: [
                      for (var d = 4; d <= 10; d++)
                        Expanded(
                            child: CalendarDayCell(
                          date: DateTime(2026, 5, d),
                          locale: 'ru',
                          isInVisibleMonth: true,
                          isSelected: false,
                          isToday: false,
                          items: const [],
                          holidays: const [],
                          hasAlarm: true,
                          shiftSchedules: [
                            ShiftSchedule(
                              id: 'shift',
                              organizationName: 'Смена',
                              colorValue: 0xFF3344FF,
                              startDate: DateTime(2026, 5, 1),
                              workDays: 1,
                              restDays: 1,
                            )
                          ],
                          onTap: () {},
                        )),
                    ])),
                Builder(
                    builder: (context) => TextButton(
                          onPressed: () => ProductionCalendarDialog.show(
                              context, DateTime(2026, 5)),
                          child: const Text('Открыть сводку'),
                        )),
              ]),
            )),
          )));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$theme $width $scale');
          final short = tester.widget<DayNumber>(
              find.byWidgetPredicate((w) => w is DayNumber && w.day == 8));
          expect(short.isShortened, isTrue);
          expect(short.isDayOff, isFalse);
          final holiday = tester.widget<DayNumber>(
              find.byWidgetPredicate((w) => w is DayNumber && w.day == 9));
          expect(holiday.isDayOff, isTrue);
          expect(find.byIcon(Icons.alarm_rounded), findsNWidgets(7));
          final number =
              find.byWidgetPredicate((w) => w is DayNumber && w.day == 8);
          final cell =
              find.ancestor(of: number, matching: find.byType(CalendarDayCell));
          expect(
              tester.getRect(cell).contains(tester.getCenter(number)), isTrue);
          if (const bool.fromEnvironment('CAPTURE_PRODUCTION') &&
              width <= 360 &&
              scale == 1) {
            final boundary = boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              await Directory('build/production-preview')
                  .create(recursive: true);
              await File('build/production-preview/${theme.name}-$width.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.tap(find.text('Открыть сводку'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Рабочих дней: 19'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });
}
