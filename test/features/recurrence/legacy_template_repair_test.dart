import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recurrence_test_support.dart';

void main() {
  test('load repairs stale yearly and monthly templates from their origins',
      () async {
    final createdAt = DateTime(2025, 1, 1);
    final firstSave = DateTime(2025, 1, 1, 10);
    final completedSave = DateTime(2025, 1, 1, 10, 0, 5);
    final birthdayDate = DateTime(2099, 6, 16);
    final paymentDate = DateTime(2099, 7, 20);
    final birthday = MemoryItem(
      id: 'rodin-origin',
      type: MemoryType.birthday,
      title: 'Родин Слава',
      body: 'Родин Слава',
      memoryDate: birthdayDate,
      createdAt: createdAt,
      updatedAt: completedSave,
      seriesId: 'rodin-series',
      repeatRule: RecurrenceFrequency.yearly.name,
      birthYear: 1958,
    );
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Интернет',
      body: 'Интернет',
      memoryDate: paymentDate,
      createdAt: createdAt,
      updatedAt: completedSave,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      amountMinor: 99900,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final staleBirthday = birthday.copyWith(
      title: 'Родин',
      body: 'Родин',
      clearBirthYear: true,
      updatedAt: firstSave,
    );
    final stalePayment = payment.copyWith(
      title: 'Интер',
      body: 'Интер',
      clearAmount: true,
      clearPaymentCategory: true,
      updatedAt: firstSave,
    );
    final initialSeries = [
      RecurrenceSeries(
        id: 'rodin-series',
        frequency: RecurrenceFrequency.yearly,
        template: staleBirthday,
        startDate: birthdayDate,
        originItemId: birthday.id,
        createdAt: firstSave,
        updatedAt: firstSave,
      ),
      RecurrenceSeries(
        id: 'subscription-series',
        frequency: RecurrenceFrequency.monthly,
        template: stalePayment,
        startDate: paymentDate,
        originItemId: payment.id,
        createdAt: firstSave,
        updatedAt: firstSave,
      ),
    ];
    final staleGeneratedBirthday = occurrenceFromSeries(
      initialSeries.first,
      DateTime(2100, 6, 16),
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1':
          encodeItems([birthday, payment, staleGeneratedBirthday]),
      LocalRecurrenceRepository.storageKey: encodeSeries(initialSeries),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
    final sync = DeletionObserver({});
    final memories = MemoryItemsController(
      const LocalMemoryRepository(),
      null,
      null,
      sync,
    );
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
      sync,
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
      sync,
    );

    await controller.load();

    final repairedBirthday =
        controller.state.singleWhere((series) => series.id == 'rodin-series');
    final nextBirthday = occurrenceFromSeries(
      repairedBirthday,
      DateTime(2100, 6, 16),
    );
    expect(nextBirthday.title, 'Родин Слава');
    expect(nextBirthday.body, 'Родин Слава');
    expect(nextBirthday.birthYear, 1958);
    expect(
      memories.state.any((item) => item.id == staleGeneratedBirthday.id),
      isFalse,
    );
    expect(exceptions.state, isEmpty);

    final repairedPayment = controller.state
        .singleWhere((series) => series.id == 'subscription-series');
    final nextPayment = occurrenceFromSeries(
      repairedPayment,
      DateTime(2099, 8, 20),
    );
    expect(nextPayment.title, 'Интернет');
    expect(nextPayment.body, 'Интернет');
    expect(nextPayment.amountMinor, 99900);
    expect(nextPayment.paymentCategory, PaymentCategory.subscription.name);

    final persisted = await const LocalRecurrenceRepository().loadAll();
    expect(
      persisted
          .singleWhere((series) => series.id == 'rodin-series')
          .template
          .title,
      'Родин Слава',
    );
    expect(
      persisted
          .singleWhere((series) => series.id == 'subscription-series')
          .template
          .amountMinor,
      99900,
    );
  });

  test('load never promotes a generated occurrence into the series template',
      () async {
    final createdAt = DateTime(2025, 1, 1);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.birthday,
      title: 'Исходное имя',
      memoryDate: DateTime(2099, 1, 9),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
      birthYear: 1991,
    );
    final generated = template.copyWith(
      id: 'series_21000109',
      title: 'Только этот год',
      memoryDate: DateTime(2100, 1, 9),
      updatedAt: createdAt.add(const Duration(days: 1)),
      isGeneratedOccurrence: true,
    );
    final moved = template.copyWith(
      id: 'series_21010109',
      memoryDate: DateTime(2101, 2, 9),
      updatedAt: createdAt.add(const Duration(days: 1)),
      isGeneratedOccurrence: true,
    );
    final orphan = template.copyWith(
      id: 'missing-series_21020109',
      memoryDate: DateTime(2102, 1, 9),
      seriesId: 'missing-series',
      updatedAt: createdAt.add(const Duration(days: 1)),
      isGeneratedOccurrence: true,
    );
    final malformed = template.copyWith(
      id: 'legacy-copy-without-date',
      memoryDate: DateTime(2103, 1, 9),
      updatedAt: createdAt.add(const Duration(days: 1)),
      isGeneratedOccurrence: true,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: template.memoryDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final newerOverride = generated.copyWith(
      title: 'Более новое исключение',
      updatedAt: createdAt.add(const Duration(days: 2)),
    );
    final existingException = RecurrenceOccurrenceException(
      id: recurrenceExceptionId('series', DateTime(2100, 1, 9)),
      seriesId: 'series',
      occurrenceDate: DateTime(2100, 1, 9),
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: newerOverride,
      createdAt: createdAt.add(const Duration(days: 2)),
      updatedAt: createdAt.add(const Duration(days: 2)),
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([generated, moved, orphan, malformed]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          encodeExceptions([existingException]),
    });
    final sync = DeletionObserver({});
    final memories = MemoryItemsController(
      const LocalMemoryRepository(),
      null,
      null,
      sync,
    );
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
      sync,
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
      sync,
    );

    await controller.load();

    expect(controller.state.single.template.title, 'Исходное имя');
    expect(controller.state.single.template.birthYear, 1991);
    expect(memories.state.map((item) => item.id), contains(orphan.id));
    expect(memories.state.map((item) => item.id), contains(malformed.id));
    expect(
        memories.state.map((item) => item.id), isNot(contains(generated.id)));
    expect(memories.state.map((item) => item.id), isNot(contains(moved.id)));
    expect(exceptions.state, hasLength(2));
    final generatedException = exceptions.state.singleWhere(
      (entry) => entry.item?.id == generated.id,
    );
    expect(generatedException.item?.title, 'Более новое исключение');
    expect(generatedException.survivesMemoryDeletion, isTrue);
    final movedException = exceptions.state.singleWhere(
      (entry) => entry.item?.id == moved.id,
    );
    expect(movedException.occurrenceDate, DateTime(2101, 1, 9));
    expect(movedException.item?.memoryDate, DateTime(2101, 2, 9));
    expect(movedException.survivesMemoryDeletion, isTrue);
  });

  test('load keeps an origin-only replacement scoped to that occurrence',
      () async {
    final seriesCreated = DateTime(2025, 1, 1, 10);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.birthday,
      title: 'Имя для серии',
      body: 'Имя для серии',
      memoryDate: DateTime(2099, 1, 9),
      createdAt: seriesCreated,
      updatedAt: seriesCreated,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
      birthYear: 1991,
    );
    final editedOrigin = template.copyWith(
      title: 'Только первая запись',
      body: 'Только первая запись',
      updatedAt: seriesCreated.add(const Duration(seconds: 5)),
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: template.memoryDate,
      originItemId: template.id,
      createdAt: seriesCreated,
      updatedAt: seriesCreated,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems([editedOrigin]),
      LocalRecurrenceRepository.storageKey: encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
    final memories = MemoryItemsController(const LocalMemoryRepository());
    final exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    final controller = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
    );

    await controller.load();

    expect(controller.state.single.template.title, 'Имя для серии');
  });
}
