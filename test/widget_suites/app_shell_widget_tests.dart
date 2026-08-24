part of '../widget_test.dart';

void registerAppShellWidgetTests() {
  testWidgets('bottom panel is drawn from the destination list',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    // Порядок кнопок задан списком пунктов, а не разбором индексов внутри
    // панели: каждая кнопка на своём месте и ни одна не особенная.
    const order = ['calendar', 'feed', 'add_note', 'accounts', 'settings'];
    for (final id in order) {
      expect(find.byKey(ValueKey('bottom_$id')), findsOneWidget);
    }
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(order.length),
    );

    await openTab(tester, 'feed');
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      order.indexOf('feed'),
    );

    await openTab(tester, 'settings');
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      order.indexOf('settings'),
    );
  });

  testWidgets('note editor keeps the panel and highlights its button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();

    expect(find.text('Новая записка'), findsOneWidget);
    // Записку заводят с панели, поэтому панель остаётся под рукой: уйти с
    // экрана можно тем же способом, каким на него пришли.
    for (final id in ['calendar', 'feed', 'add_note', 'accounts', 'settings']) {
      expect(find.byKey(ValueKey('bottom_$id')), findsOneWidget);
    }
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    // И панель по-прежнему уводит на вкладки, а не запирает в редакторе.
    await openTab(tester, 'calendar');
    expect(find.text('Новая записка'), findsNothing);
  });
}
