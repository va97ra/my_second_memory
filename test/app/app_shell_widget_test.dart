import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('the back key is the same size in every header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    Size visibleKey() => tester.getSize(
          find
              .descendant(
                of: find.byKey(const ValueKey('app_back')),
                matching: find.byType(Material),
              )
              .first,
        );

    // Шапка страницы и шапка AppBar устроены по-разному, и вторая норовит
    // растянуть кнопку на весь свой слот. Клавиша должна быть одна и та же:
    // разные размеры одной кнопки на соседних экранах видно невооружённым
    // глазом.
    await openTab(tester, 'accounts');
    final inPageHeader = visibleKey();

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();
    final inAppBar = visibleKey();

    const expected = Size(notebookIconButtonSize, notebookIconButtonSize);
    expect(inPageHeader, expected);
    expect(inAppBar, expected);
  });

  testWidgets('bottom panel is drawn from the destination list',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
    expect(tester.widget<AppNavBar>(find.byType(AppNavBar)).items,
        hasLength(order.length));

    await openTab(tester, 'feed');
    expect(
      tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
      order.indexOf('feed'),
    );

    await openTab(tester, 'settings');
    expect(
      tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
      order.indexOf('settings'),
    );
  });

  testWidgets('top and bottom panels own separate ink surfaces',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    MaterialInkController inkOf(Key key) {
      final ink = find.descendant(
        of: find.byKey(key),
        matching: find.byType(InkWell),
      );
      return Material.of(tester.element(ink));
    }

    // Нажатие на нижнюю кнопку не должно инвалидировать общий со всей
    // оболочкой ink-слой: на настоящем Android это на кадр перерисовывало
    // кожаную фактуру верхних инструментов и выглядело как вспышка.
    expect(
      identical(
        inkOf(const ValueKey('top_calculator')),
        inkOf(const ValueKey('bottom_feed')),
      ),
      isFalse,
    );
  });

  testWidgets('top panel uses the scaffold app bar slot outside the page body',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    final shellScaffold = tester.widget<Scaffold>(
      find
          .ancestor(
            of: find.byType(AppNavBar),
            matching: find.byType(Scaffold),
          )
          .first,
    );

    expect(shellScaffold.appBar, isNotNull);
    expect(
      find.descendant(
        of: find.byWidget(shellScaffold.appBar!),
        matching: find.byType(AppToolBar),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byWidget(shellScaffold.body!),
        matching: find.byType(AppToolBar),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byWidget(shellScaffold.body!),
        matching: find.byType(PageTurnFrame),
      ),
      findsOneWidget,
    );
  });

  testWidgets('bottom navigation does not rebuild the top panel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    var topPanelRebuilds = 0;
    final previousRebuildObserver = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      previousRebuildObserver?.call(element, builtOnce);
      if (builtOnce && element.widget is AppToolBar) topPanelRebuilds += 1;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previousRebuildObserver);

    await tester.tap(find.byKey(const ValueKey('bottom_feed')));
    await tester.pumpAndSettle();

    expect(
      topPanelRebuilds,
      0,
      reason: 'смена нижней вкладки перерисовала кожаную подложку сверху',
    );
  });

  testWidgets('tools replace each other and back returns to the source panel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'feed');

    expect(find.byKey(const ValueKey('top_calculator')), findsOneWidget);
    expect(find.byKey(const ValueKey('top_finance')), findsOneWidget);
    expect(find.byKey(const ValueKey('top_converter')), findsOneWidget);
    // Два свободных места сняты с панели: пустая кнопка занимала ширину на
    // каждом экране. Маршруты и экран остались, кнопок больше нет.
    expect(find.byKey(const ValueKey('top_slot_one')), findsNothing);
    expect(find.byKey(const ValueKey('top_slot_two')), findsNothing);
    final tools = tester.widget<AppToolBar>(find.byType(AppToolBar)).items;
    expect(tools, hasLength(3));
    expect(find.byType(AppNavigationItems), findsNWidgets(2));
    expect(tester.widget<AppToolBar>(find.byType(AppToolBar)).selectedIndex,
        isNull);

    await tester.tap(find.byKey(const ValueKey('top_calculator')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calculator_expression')), findsOneWidget);
    expect(tester.widget<AppToolBar>(find.byType(AppToolBar)).selectedIndex, 0);
    expect(
      tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('top_finance')));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('app_page_turn_overlay')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('finance_currency')), findsOneWidget);
    expect(find.byKey(const ValueKey('calculator_expression')), findsNothing);
    expect(tester.widget<AppToolBar>(find.byType(AppToolBar)).selectedIndex, 1);
    expect(
      tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('top_converter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('converter_screen')), findsOneWidget);
    expect(tester.widget<AppToolBar>(find.byType(AppToolBar)).selectedIndex, 2);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('finance_currency')), findsNothing);
    expect(find.byKey(const ValueKey('calculator_expression')), findsNothing);
    expect(tester.widget<AppToolBar>(find.byType(AppToolBar)).selectedIndex,
        isNull);
    expect(tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex, 1);
  });

  testWidgets('top tools stay available on a nested editor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();
    expect(find.text('Новая записка'), findsOneWidget);
    expect(find.byType(AppToolBar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('top_calculator')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Новая записка'), findsOneWidget);
    expect(find.byType(AppToolBar), findsOneWidget);
    expect(tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex, 2);
  });

  testWidgets('the panel survives the first autosave of a note',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FeedMemoryRepository();

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bottom_add_note')), findsOneWidget);

    // Первая же буква запускает автосохранение: черновик становится записью,
    // и адрес экрана меняется. Панель обязана это пережить - человек с неё не
    // уходил.
    await tester.enterText(
      find.byKey(const ValueKey('record_editor_text')),
      'Проверка панели',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repository.savedItems.any((item) => item.isUndated), isTrue);
    for (final id in ['calendar', 'feed', 'add_note', 'accounts', 'settings']) {
      expect(
        find.byKey(ValueKey('bottom_$id')),
        findsOneWidget,
        reason: 'кнопка $id пропала после автосохранения',
      );
    }
    expect(
      tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
      2,
    );
  });

  testWidgets('note editor keeps the panel and highlights its button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
      tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
      2,
    );

    // И панель по-прежнему уводит на вкладки, а не запирает в редакторе.
    await openTab(tester, 'calendar');
    expect(find.text('Новая записка'), findsNothing);
  });

  testWidgets('panels stay out of the page turn', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('top_calculator')));
    await tester.pumpAndSettle();

    // Оболочка одна на всё приложение: страница, открытая поверх другой, свою
    // пару панелей с собой не приносит. Пока приносила, в переворачиваемом
    // листе ехала старая пара, под ним стояла новая, и тень листа мелькала по
    // кнопкам.
    expect(find.byType(AppToolBar), findsOneWidget);
    expect(find.byType(AppNavBar), findsOneWidget);

    // Переворачивается только лист между панелями.
    final turn = tester.getRect(find.byType(PageTurnFrame));
    expect(turn.top, tester.getRect(find.byType(AppToolBar)).bottom);
    expect(turn.bottom, tester.getRect(find.byType(AppNavBar)).top);
  });
}
