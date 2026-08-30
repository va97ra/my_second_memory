import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('settings opens shift schedules and saves preset',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final memoryRepository = FeedMemoryRepository();
    final shiftRepository = FakeShiftScheduleRepository();

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          shiftScheduleRepositoryProvider.overrideWithValue(shiftRepository),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    final shiftSchedules = find.text('Графики смен');
    await tester.ensureVisible(shiftSchedules);
    await tester.pumpAndSettle();
    await tester.tap(shiftSchedules);
    await tester.pumpAndSettle();

    expect(find.text('Графики смен'), findsWidgets);
    expect(find.text('Графиков пока нет'), findsOneWidget);

    await tester.tap(find.text('Добавить график').last);
    await tester.pumpAndSettle();

    expect(find.text('5/2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('сутки/трое'), findsOneWidget);
    expect(find.text('7/7'), findsNothing);
    expect(find.text('14/14'), findsNothing);
    expect(find.byKey(const ValueKey('shift_color_hue')), findsOneWidget);
    expect(find.byKey(const ValueKey('shift_color_tone')), findsOneWidget);
    expect(find.byKey(const ValueKey('shift_color_preview')), findsOneWidget);
    expect(find.text('Будильник 1'), findsOneWidget);
    expect(find.textContaining('Будильник 2'), findsNothing);
    await tester.tap(find.text('сутки/трое'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Будильник 2'), findsOneWidget);
    expect(find.text('Рабочих дней'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Организация'),
      'Завод',
    );
    await tester.tap(find.text('2/2'));
    await tester.pumpAndSettle();
    final hueTrack = find.byKey(const ValueKey('shift_color_hue'));
    final toneTrack = find.byKey(const ValueKey('shift_color_tone'));
    final hueRect = tester.getRect(hueTrack);
    final toneRect = tester.getRect(toneTrack);
    await tester.tapAt(Offset(
      hueRect.left + hueRect.width * 0.72,
      hueRect.center.dy,
    ));
    await tester.tapAt(Offset(
      toneRect.left + toneRect.width * 0.38,
      toneRect.center.dy,
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_shift_vacation')));
    await tester.pumpAndSettle();
    expect(find.text('Количество календарных дней'), findsOneWidget);
    expect(find.byKey(const ValueKey('vacation_end_date_preview')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save_shift_vacation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shift_vacations_empty')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_shift_vacation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_shift_vacation')));
    await tester.pumpAndSettle();
    expect(
      find.text('Этот период пересекается с другим отпуском'),
      findsOneWidget,
    );
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();

    final removeVacation = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('remove_shift_vacation_'),
    );
    await tester.ensureVisible(removeVacation);
    await tester.pumpAndSettle();
    await tester.tap(removeVacation);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shift_vacations_empty')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_shift_vacation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_shift_vacation')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(shiftRepository.savedSchedules, hasLength(1));
    expect(shiftRepository.savedSchedules.single.organizationName, 'Завод');
    expect(shiftRepository.savedSchedules.single.workDays, 2);
    expect(shiftRepository.savedSchedules.single.restDays, 2);
    expect(
      shiftRepository.savedSchedules.single.colorValue,
      isNot(const Color(0xFF2F7DD1).toARGB32()),
    );
    expect(shiftRepository.savedSchedules.single.vacations, hasLength(1));
    expect(shiftRepository.savedSchedules.single.vacations.single.durationDays,
        14);
  });

  testWidgets('settings opens memory archive and restores item to feed',
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
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Архив памяти'));
    await tester.pumpAndSettle();

    expect(find.text('Архив памяти'), findsWidgets);
    expect(find.text('Архивная запись'), findsOneWidget);
    expect(find.text('План на сегодня'), findsNothing);
    // Фильтр стоит кнопкой в шапке, как в ленте, а не рядом чипов под ней.
    expect(find.byKey(const ValueKey('feed_filter')), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
    await tester.tap(find.byTooltip('Вернуть в ленту'));
    await tester.pumpAndSettle();

    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'archived-note')
          .status,
      MemoryStatus.active,
    );
    expect(find.text('Архивная запись'), findsNothing);

    await tester.tap(find.text('Лента').last);
    await tester.pumpAndSettle();

    expect(find.text('Архивная запись'), findsOneWidget);
  });

  testWidgets('settings opens backup screen', (tester) async {
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
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    final backup = find.text('Резервная копия');
    await tester.ensureVisible(backup);
    await tester.pumpAndSettle();
    await tester.tap(backup);
    await tester.pumpAndSettle();

    expect(find.text('Сохранить резервную копию'), findsOneWidget);
    expect(find.text('Архив будет сохранён в папку Загрузки.'), findsOneWidget);
    expect(find.text('Восстановить из копии'), findsOneWidget);

    await tester.tap(find.text('Сохранить резервную копию'));
    await tester.pumpAndSettle();
    final password = find.byKey(const ValueKey('backup_password'));
    final confirmation =
        find.byKey(const ValueKey('backup_password_confirmation'));
    expect(password, findsOneWidget);
    expect(confirmation, findsOneWidget);
    await tester.enterText(password, 'correct-password');
    await tester.enterText(confirmation, 'mistyped-password');
    await tester.tap(find.byKey(const ValueKey('backup_password_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    expect(confirmation, findsOneWidget);
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();
  });
}
