import 'dart:convert';

import 'package:ezhednevnik_v2/src/features/memory_items/data/local_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/notifications/data/notification_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/local_recurrence_exception_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/local_recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_occurrence_exception.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_projection_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:ezhednevnik_v2/src/features/sync/domain/sync_mutation_observer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          _encodeItems([birthday, payment, staleGeneratedBirthday]),
      LocalRecurrenceRepository.storageKey: _encodeSeries(initialSeries),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });
    final sync = _DeletionObserver({});
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
      'memory_items_v1': _encodeItems([generated, moved, orphan, malformed]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          _encodeExceptions([existingException]),
    });
    final sync = _DeletionObserver({});
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
      'memory_items_v1': _encodeItems([editedOrigin]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

  test('load repairs a legacy name completed by prepending text', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final completedAt = createdAt.add(const Duration(seconds: 5));
    final occurrenceDate = DateTime(2099, 1, 9);
    final origin = MemoryItem(
      id: 'anastasia-origin',
      type: MemoryType.birthday,
      title: 'Железнякова Анастасия',
      body: 'Железнякова Анастасия',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: completedAt,
      seriesId: 'anastasia-series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final staleTemplate = origin.copyWith(
      title: 'Анаста',
      body: 'Анаста',
      updatedAt: createdAt,
    );
    final series = RecurrenceSeries(
      id: 'anastasia-series',
      frequency: RecurrenceFrequency.yearly,
      template: staleTemplate,
      startDate: occurrenceDate,
      originItemId: origin.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([origin]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    expect(controller.state.single.template.title, 'Железнякова Анастасия');
    expect(controller.state.single.template.body, 'Железнякова Анастасия');
  });

  test('load does not promote text appended to only the origin occurrence',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Купить',
      body: 'Купить',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final editedOrigin = template.copyWith(
      title: 'Купить молоко',
      body: 'Купить молоко',
      updatedAt: createdAt.add(const Duration(seconds: 5)),
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([editedOrigin]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    expect(controller.state.single.template.title, 'Купить');
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Купить молоко',
      reason: 'the record shows the edit, wherever it is stored',
    );
  });

  test('load does not promote an interior word fragment', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'дом',
      body: 'дом',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final editedOrigin = template.copyWith(
      title: 'уведомление',
      body: 'уведомление',
      updatedAt: createdAt.add(const Duration(seconds: 5)),
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([editedOrigin]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    expect(controller.state.single.template.title, 'дом');
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'уведомление',
      reason: 'the record shows the edit, wherever it is stored',
    );
  });

  test('origin override marker prevents metadata edits becoming a template',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.birthday,
      title: 'Анастасия',
      body: 'Анастасия',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([template]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    await controller.saveOccurrenceOverride(
      template.copyWith(
        birthYear: 1991,
        updatedAt: createdAt.add(const Duration(minutes: 5)),
      ),
      occurrenceDate: occurrenceDate,
    );

    expect(exceptions.state, hasLength(1));
    expect(exceptions.state.single.item?.id, template.id);
    // Every occurrence, the first one included, is projected from the series.
    expect(exceptions.state.single.item?.isGeneratedOccurrence, isTrue);
    expect(exceptions.state.single.item?.birthYear, 1991);
    expect(memories.state, isEmpty);

    final reloadedMemories =
        MemoryItemsController(const LocalMemoryRepository());
    final reloadedExceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
    );
    final reloadedReminders = NotificationService();
    addTearDown(reloadedReminders.dispose);
    final reloaded = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      reloadedExceptions,
      reloadedMemories,
      reloadedReminders,
    );
    await reloaded.load();

    expect(reloaded.state.single.template.birthYear, isNull);
    expect(reloadedExceptions.state.single.item?.birthYear, 1991);
    expect(reloadedExceptions.state, hasLength(1));
  });

  test('load restores a newer origin override after a partial write', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Старое значение',
      body: 'Старое значение',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final overrideItem = template.copyWith(
      title: 'Новое значение',
      body: 'Новое значение',
      updatedAt: createdAt.add(const Duration(seconds: 5)),
    );
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, occurrenceDate),
      seriesId: series.id,
      occurrenceDate: occurrenceDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: overrideItem,
      createdAt: overrideItem.updatedAt,
      updatedAt: overrideItem.updatedAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([template]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          _encodeExceptions([exception]),
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

    expect(controller.state.single.template.title, 'Старое значение');
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Новое значение',
      reason: 'the record shows the edit, wherever it is stored',
    );
    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Новое значение',
    );
    expect(
      (await const LocalRecurrenceExceptionRepository().loadAll())
          .single
          .item
          ?.title,
      'Новое значение',
    );
  });

  test('downloaded origin override is reconciled without a restart', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final occurrenceDate = DateTime(2099, 1, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Локальное значение',
      body: 'Локальное значение',
      memoryDate: occurrenceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: occurrenceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([template]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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
    final remoteItem = template.copyWith(
      title: 'Значение с другого устройства',
      body: 'Значение с другого устройства',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    await exceptions.replaceAll([
      RecurrenceOccurrenceException(
        id: recurrenceExceptionId(series.id, occurrenceDate),
        seriesId: series.id,
        occurrenceDate: occurrenceDate,
        kind: RecurrenceOccurrenceExceptionKind.modified,
        item: remoteItem,
        createdAt: remoteItem.updatedAt,
        updatedAt: remoteItem.updatedAt,
      ),
    ]);

    await controller.reconcileOriginOverrides();

    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Значение с другого устройства',
      reason: 'the record shows the edit, wherever it is stored',
    );
  });

  test('moved origin can be deleted without returning from its marker',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Встреча',
      body: 'Встреча',
      memoryDate: sourceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: sourceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([template]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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
    await controller.saveOccurrenceOverride(
      template.copyWith(memoryDate: movedDate),
      occurrenceDate: sourceDate,
    );
    final moved = exceptions.state.single.item!;
    final duplicateUpdatedAt = moved.updatedAt.add(const Duration(seconds: 1));
    await exceptions.upsert(
      RecurrenceOccurrenceException(
        id: recurrenceExceptionId(series.id, movedDate),
        seriesId: series.id,
        occurrenceDate: movedDate,
        kind: RecurrenceOccurrenceExceptionKind.modified,
        item: moved.copyWith(updatedAt: duplicateUpdatedAt),
        createdAt: moved.updatedAt,
        updatedAt: duplicateUpdatedAt,
      ),
    );

    await controller.deleteOccurrence(moved);

    expect(memories.state, isEmpty);
    expect(exceptions.state, hasLength(1));
    expect(exceptions.state.single.isSkipped, isTrue);
    expect(exceptions.state.single.occurrenceDate, sourceDate);
    expect(
      const RecurrenceProjectionService().itemsForRange(
        start: sourceDate,
        end: movedDate,
        series: controller.state,
        exceptions: exceptions.state,
        persistedItems: memories.state,
      ),
      isEmpty,
    );
  });

  test('load recovers the newest partial edit of a moved origin', () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final template = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Исходное значение',
      body: 'Исходное значение',
      memoryDate: sourceDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final moved = template.copyWith(
      title: 'Первая правка',
      body: 'Первая правка',
      memoryDate: movedDate,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    final newest = moved.copyWith(
      title: 'Вторая правка',
      body: 'Вторая правка',
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: template,
      startDate: sourceDate,
      originItemId: template.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final deletionTime = createdAt.add(const Duration(seconds: 90));
    final olderSkip = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, sourceDate),
      seriesId: series.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: deletionTime,
      updatedAt: deletionTime,
    );
    final misplacedNewestMarker = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, movedDate),
      seriesId: series.id,
      occurrenceDate: movedDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: newest,
      createdAt: newest.updatedAt,
      updatedAt: newest.updatedAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([moved]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          _encodeExceptions([olderSkip, misplacedNewestMarker]),
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

    expect(
      const RecurrenceProjectionService()
          .itemById(
            id: template.id,
            series: controller.state,
            exceptions: exceptions.state,
            persistedItems: memories.state,
          )
          ?.title,
      'Вторая правка',
      reason: 'the record shows the edit, wherever it is stored',
    );
    expect(exceptions.state, hasLength(1));
    expect(exceptions.state.single.occurrenceDate, sourceDate);
    expect(exceptions.state.single.item?.title, 'Вторая правка');
  });

  test('load completes a deletion after its skip was committed first',
      () async {
    final createdAt = DateTime(2025, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final moved = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Удаляемая встреча',
      body: 'Удаляемая встреча',
      memoryDate: movedDate,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: moved.copyWith(
        memoryDate: sourceDate,
        updatedAt: createdAt,
      ),
      startDate: sourceDate,
      originItemId: moved.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final deletionTime = createdAt.add(const Duration(minutes: 2));
    final skip = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, sourceDate),
      seriesId: series.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      item: moved,
      createdAt: deletionTime,
      updatedAt: deletionTime,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([moved]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: _encodeExceptions([skip]),
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

    expect(memories.state, isEmpty);
    expect((await const LocalMemoryRepository().loadAll()), isEmpty);
    expect(exceptions.state.single.isSkipped, isTrue);
  });

  test('memory tombstone defeats stale moved markers downloaded from cloud',
      () async {
    final createdAt = DateTime(2026, 1, 1, 10);
    final sourceDate = DateTime(2099, 1, 9);
    final movedDate = DateTime(2099, 2, 9);
    final moved = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Удалённая встреча',
      memoryDate: movedDate,
      createdAt: createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: moved.copyWith(memoryDate: sourceDate),
      startDate: sourceDate,
      originItemId: moved.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final modified = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, sourceDate),
      seriesId: series.id,
      occurrenceDate: sourceDate,
      kind: RecurrenceOccurrenceExceptionKind.modified,
      item: moved,
      createdAt: moved.updatedAt,
      updatedAt: moved.updatedAt,
    );
    final legacyDestinationSkip = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(series.id, movedDate),
      seriesId: series.id,
      occurrenceDate: movedDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: moved.updatedAt.add(const Duration(minutes: 1)),
      updatedAt: moved.updatedAt.add(const Duration(minutes: 1)),
    );
    final deletedAt = moved.updatedAt.add(const Duration(minutes: 1));
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': '[]',
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey:
          _encodeExceptions([modified, legacyDestinationSkip]),
    });
    final sync = _DeletionObserver({moved.id: deletedAt});
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

    expect(memories.state, isEmpty);
    final sourceMarker = exceptions.state.singleWhere(
      (entry) => dateKey(entry.occurrenceDate) == dateKey(sourceDate),
    );
    expect(sourceMarker.isSkipped, isTrue);
    expect(sourceMarker.item?.id, moved.id);
    expect(
      const RecurrenceProjectionService().itemsForRange(
        start: sourceDate,
        end: movedDate,
        series: controller.state,
        exceptions: exceptions.state,
        persistedItems: memories.state,
      ),
      isEmpty,
    );
  });

  test('past moved occurrence survives reload and stays deleted afterwards',
      () async {
    final today = dateOnly(DateTime.now());
    final sourceDate = DateTime(today.year - 1, 5, 12);
    final movedDate = sourceDate.add(const Duration(days: 2));
    final startDate = DateTime(sourceDate.year - 1, 5, 12);
    final createdAt = DateTime(today.year - 2, 1, 1, 10);
    final origin = MemoryItem(
      id: 'origin',
      type: MemoryType.event,
      title: 'Встреча',
      memoryDate: startDate,
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'series',
      repeatRule: RecurrenceFrequency.yearly.name,
    );
    final series = RecurrenceSeries(
      id: 'series',
      frequency: RecurrenceFrequency.yearly,
      template: origin,
      startDate: startDate,
      originItemId: origin.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      historyThrough: today,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([origin]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
      LocalRecurrenceExceptionRepository.storageKey: '[]',
    });

    Future<({
      RecurrenceSeriesController controller,
      RecurrenceExceptionController exceptions,
      MemoryItemsController memories,
    })> loadControllers() async {
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
      return (
        controller: controller,
        exceptions: exceptions,
        memories: memories,
      );
    }

    final first = await loadControllers();
    final moved = occurrenceFromSeries(series, sourceDate).copyWith(
      memoryDate: movedDate,
      body: 'Перенесено',
    );
    await first.controller.saveOccurrenceOverride(
      moved,
      occurrenceDate: sourceDate,
    );

    final reloaded = await loadControllers();
    // The moved occurrence lives in its exception only; nothing about it is
    // materialized into a memory row any more.
    expect(
      reloaded.memories.state.map((item) => item.id),
      isNot(contains(occurrenceId(series.id, sourceDate))),
    );
    expect(reloaded.exceptions.state.single.isSkipped, isFalse);
    final movedOccurrence = const RecurrenceProjectionService()
        .itemsForRange(
          start: sourceDate,
          end: movedDate,
          series: reloaded.controller.state,
          exceptions: reloaded.exceptions.state,
          persistedItems: reloaded.memories.state,
        )
        .single;
    expect(movedOccurrence.memoryDate, movedDate);

    await reloaded.controller.deleteOccurrence(movedOccurrence);
    final afterDelete = await loadControllers();

    expect(
      afterDelete.memories.state.map((item) => item.id),
      isNot(contains(movedOccurrence.id)),
    );
    expect(afterDelete.exceptions.state.single.isSkipped, isTrue);
    expect(
      const RecurrenceProjectionService().itemsForRange(
        start: sourceDate,
        end: movedDate,
        series: afterDelete.controller.state,
        exceptions: afterDelete.exceptions.state,
        persistedItems: afterDelete.memories.state,
      ),
      isEmpty,
    );
  });

  test('subscription term limits monthly occurrences and can be cleared',
      () async {
    final createdAt = DateTime(2025, 1, 1);
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: DateTime(2099, 1, 31),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      amountMinor: 49900,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: payment,
      startDate: payment.memoryDate,
      originItemId: payment.id,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([payment]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    final threeMonths =
        await controller.setTermMonths('subscription-series', 3);
    expect(threeMonths?.subscriptionEndDate, DateTime(2099, 3, 31));
    expect(threeMonths?.endDate, isNull);
    expect(
      recurrenceDatesInRange(
        threeMonths!,
        DateTime(2099),
        DateTime(2101),
      ),
      [
        DateTime(2099, 1, 31),
        DateTime(2099, 2, 28),
        DateTime(2099, 3, 31),
      ],
    );

    final fourteenMonths =
        await controller.setTermMonths('subscription-series', 14);
    expect(fourteenMonths?.subscriptionEndDate, DateTime(2100, 2, 28));
    expect(
      recurrenceDatesInRange(
        fourteenMonths!,
        DateTime(2099),
        DateTime(2101),
      ),
      hasLength(14),
    );

    final unlimited =
        await controller.setTermMonths('subscription-series', null);
    expect(unlimited?.subscriptionEndDate, isNull);
    expect(
      recurrenceDatesInRange(
        unlimited!,
        DateTime(2099),
        DateTime(2101),
      ).length,
      greaterThan(14),
    );
  });

  test('clearing a subscription term preserves a deletion cutoff', () async {
    final createdAt = DateTime(2025, 1, 1);
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: DateTime(2099, 1, 15),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final deletionCutoff = DateTime(2099, 5, 14);
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: payment,
      startDate: payment.memoryDate,
      originItemId: payment.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      endDate: deletionCutoff,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([payment]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    await controller.setTermMonths('subscription-series', 3);
    final cleared = await controller.setTermMonths('subscription-series', null);

    expect(cleared?.subscriptionEndDate, isNull);
    expect(cleared?.endDate, deletionCutoff);
    expect(
      recurrenceDatesInRange(cleared!, DateTime(2099), DateTime(2100)),
      [
        DateTime(2099, 1, 15),
        DateTime(2099, 2, 15),
        DateTime(2099, 3, 15),
        DateTime(2099, 4, 15),
      ],
    );
  });

  test('splitting a subscription keeps its existing absolute end date',
      () async {
    final createdAt = DateTime(2025, 1, 1);
    final payment = MemoryItem(
      id: 'subscription-origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: DateTime(2099, 1, 15),
      createdAt: createdAt,
      updatedAt: createdAt,
      seriesId: 'subscription-series',
      repeatRule: RecurrenceFrequency.monthly.name,
      paymentCategory: PaymentCategory.subscription.name,
    );
    final series = RecurrenceSeries(
      id: 'subscription-series',
      frequency: RecurrenceFrequency.monthly,
      template: payment,
      startDate: payment.memoryDate,
      originItemId: payment.id,
      createdAt: createdAt,
      updatedAt: createdAt,
      subscriptionEndDate: DateTime(2099, 12, 15),
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': _encodeItems([payment]),
      LocalRecurrenceRepository.storageKey: _encodeSeries([series]),
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

    final june = DateTime(2099, 6, 15);
    final edited = occurrenceFromSeries(controller.state.single, june);
    final replacement = await controller.applyToFuture(
      edited,
      occurrenceDate: june,
    );
    final unchangedTerm = await controller.setTermMonths(replacement!.id, 7);

    expect(unchangedTerm?.startDate, june);
    expect(unchangedTerm?.subscriptionEndDate, DateTime(2099, 12, 15));
    expect(
      recurrenceDatesInRange(
        unchangedTerm!,
        june,
        DateTime(2100, 1, 1),
      ),
      [
        DateTime(2099, 6, 15),
        DateTime(2099, 7, 15),
        DateTime(2099, 8, 15),
        DateTime(2099, 9, 15),
        DateTime(2099, 10, 15),
        DateTime(2099, 11, 15),
        DateTime(2099, 12, 15),
      ],
    );
  });
}

String _encodeItems(List<MemoryItem> items) =>
    jsonEncode(items.map((item) => item.toJson()).toList());

String _encodeSeries(List<RecurrenceSeries> series) =>
    jsonEncode(series.map((item) => item.toJson()).toList());

String _encodeExceptions(List<RecurrenceOccurrenceException> exceptions) =>
    jsonEncode(exceptions.map((item) => item.toJson()).toList());

class _DeletionObserver extends NoopSyncMutationObserver {
  _DeletionObserver(this.deletedAtById);

  final Map<String, DateTime> deletedAtById;

  @override
  Future<void> memoryDeleted(String id, DateTime deletedAt) async {
    deletedAtById[id] = deletedAt;
  }

  @override
  Future<DateTime?> memoryDeletedAt(String id) async => deletedAtById[id];

  @override
  Future<Map<String, DateTime>> memoryDeletions() async =>
      Map.unmodifiable(deletedAtById);
}
