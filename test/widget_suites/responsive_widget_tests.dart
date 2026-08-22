part of '../widget_test.dart';

void registerResponsiveWidgetTests() {
  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('dense feed adapts at ${width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        testProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'feed');

      final card = find.byKey(const ValueKey('memory_card_today-plan'));
      await tester.scrollUntilVisible(
        card,
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('feed_dated_scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(card).height,
        closeTo(88, 0.1),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('memory_card_done_today-plan')),
        ),
        const Size.square(36),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('dense feed supports ${scale}x text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        testProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'feed');

      final card = find.byKey(const ValueKey('memory_card_today-plan'));
      if (card.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          card,
          180,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('feed_dated_scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
      }
      final expectedHeight = scale <= 1.3
          ? 76 + ((scale - 1).clamp(0.0, 0.3) * 40)
          : 88 + (((scale - 1.3) / 0.7).clamp(0.0, 1.0) * 64);
      expect(
        tester.getSize(card).height,
        closeTo(expectedHeight, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final style in AppThemeStyle.values) {
    testWidgets('dense feed renders in ${style.name} theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        testProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
            appThemeControllerProvider.overrideWith(
              (ref) => AppThemeController(
                initialStyle: style,
                loadOnStart: false,
              ),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'feed');

      expect(
        find.byKey(const ValueKey('memory_card_today-plan')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('vacation editor stays reachable at ${width.toInt()} px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );

      await tester.pumpWidget(
        testProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки').last);
      await tester.pumpAndSettle();
      final shiftSchedules = find.text('Графики смен');
      await tester.ensureVisible(shiftSchedules);
      await tester.pumpAndSettle();
      await tester.tap(shiftSchedules);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить график').last);
      await tester.pumpAndSettle();

      final addVacation = find.byKey(const ValueKey('add_shift_vacation'));
      await tester.ensureVisible(addVacation);
      await tester.pumpAndSettle();
      expect(tester.getSize(addVacation).height, 48);
      await tester.tap(addVacation);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vacation_start_date')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vacation_duration_days')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
