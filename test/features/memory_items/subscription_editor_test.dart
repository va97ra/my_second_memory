import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/navigation/app_router.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('calendar header holds its bands at ${scale}x text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        testProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              FakeShiftScheduleRepository([
                ShiftSchedule(
                  id: 'factory',
                  organizationName: 'СВ Консалтинг',
                  colorValue: 0xFF2563EB,
                  startDate: DateTime.now(),
                  workDays: 5,
                  restDays: 2,
                ),
              ]),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'calendar');

      // The band never spills: pumping would have thrown on an overflow.
      final header = tester.getRect(
        find.byKey(const ValueKey('calendar_header_card')),
      );
      expect(header.height % notebookPageLineHeight, closeTo(0, 0.01));
      expect(
        find.byKey(const ValueKey('calendar_shift_legend')),
        findsOneWidget,
      );
    });
  }

  testWidgets('subscription editor accepts a term in years and months',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(EmptyMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    final todayCell = find.text('${today.day}').first;
    await tester.ensureVisible(todayCell);
    await tester.tap(todayCell);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar_day_add_record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('memory_type_picker')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Платёж'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Платёж').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<PaymentCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подписка').last);
    await tester.pumpAndSettle();

    final termPicker = find.byKey(const ValueKey('subscription_term_picker'));
    expect(termPicker, findsOneWidget);
    expect(find.text('Без срока'), findsOneWidget);
    await tester.tap(termPicker);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('subscription_term_unlimited')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('subscription_term_years')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subscription_term_months')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    final saveTerm = find.byKey(const ValueKey('subscription_term_save'));
    await tester.ensureVisible(saveTerm);
    await tester.pumpAndSettle();
    await tester.tap(saveTerm);
    await tester.pumpAndSettle();

    expect(find.text('1 год 2 месяца'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('future subscription edit shows only its remaining term',
      (tester) async {
    final now = DateTime.now();
    final createdAt = DateTime(now.year, 1, 1);
    final startDate = DateTime(now.year, 1, 15);
    final juneDate = DateTime(now.year, 6, 15);
    final origin = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Видеосервис',
      body: 'Видеосервис',
      memoryDate: startDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: origin,
      startDate: startDate,
      originItemId: origin.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      subscriptionEndDate: DateTime(now.year, 12, 15),
      historyThrough: DateTime(now.year, now.month, now.day),
    );
    SharedPreferences.setMockInitialValues({
      LocalRecurrenceRepository.storageKey: jsonEncode([series.toJson()]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
    addTearDown(() => SharedPreferences.setMockInitialValues({}));
    final repository = EmptyMemoryRepository()..savedItems = [origin];
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(EzhednevnikV2App)),
    );
    container.read(appRouterProvider).go(
          '/memory/item/${Uri.encodeComponent(occurrenceId(series.id, juneDate))}',
        );
    await tester.pumpAndSettle();

    expect(find.text('Редактировать только эту запись'), findsOneWidget);
    await tester.tap(find.text('Эту и будущие записи'));
    await tester.pumpAndSettle();

    final picker = find.byKey(const ValueKey('subscription_term_picker'));
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    expect(find.text('7 месяцев'), findsOneWidget);

    await tester.tap(picker);
    await tester.pumpAndSettle();
    final saveTerm = find.byKey(const ValueKey('subscription_term_save'));
    await tester.ensureVisible(saveTerm);
    await tester.tap(saveTerm);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final persistedSeries = await const LocalRecurrenceRepository().loadAll();
    final replacement = persistedSeries.singleWhere(
      (entry) =>
          entry.id != series.id &&
          entry.startDate == juneDate &&
          entry.originItemId == occurrenceId(series.id, juneDate),
    );
    expect(replacement.subscriptionEndDate, DateTime(now.year, 12, 15));

    container.read(appRouterProvider).go('/calendar');
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(
          '/memory/item/${Uri.encodeComponent(replacement.originItemId)}',
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Эту и будущие записи'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('subscription_term_picker')),
    );
    expect(find.text('7 месяцев'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
