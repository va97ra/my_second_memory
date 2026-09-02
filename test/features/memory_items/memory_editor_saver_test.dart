import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_editor_draft.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_editor_saver.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

MemoryEditorDraft _draft({
  required DateTime savedAt,
  String body = 'Интернет',
  MemoryType type = MemoryType.note,
  DateTime? memoryDate,
  String? repeatRule,
  int? amountMinor,
  String? paymentCategory,
  int? subscriptionTermMonths,
  bool subscriptionTermDirty = false,
}) {
  return MemoryEditorDraft(
    type: type,
    title: body,
    body: body,
    timeMinutes: null,
    endMinutes: null,
    remindAt: null,
    reminderSoundUri: null,
    reminderSoundName: null,
    memoryDate: memoryDate ?? DateTime(2026, 3, 10),
    status: MemoryStatus.active,
    audioPath: null,
    audioDurationSeconds: null,
    imagePaths: const [],
    savedAt: savedAt,
    repeatRule: repeatRule,
    amountMinor: amountMinor,
    paymentCategory: paymentCategory,
    subscriptionTermMonths: subscriptionTermMonths,
    subscriptionTermDirty: subscriptionTermDirty,
    birthYear: null,
    isUndated: false,
  );
}

class _Controllers {
  _Controllers(this.memories, this.series, this.exceptions);

  final MemoryItemsController memories;
  final RecurrenceSeriesController series;
  final RecurrenceExceptionController exceptions;

  MemoryEditorSaver get saver =>
      MemoryEditorSaver(items: memories, series: series);
}

Future<_Controllers> _controllers() async {
  final memories = MemoryItemsController(const LocalMemoryRepository());
  await memories.load();
  final exceptions = RecurrenceExceptionController(
    const LocalRecurrenceExceptionRepository(),
  );
  await exceptions.load();
  final reminders = NotificationService();
  addTearDown(reminders.dispose);
  final series = RecurrenceSeriesController(
    const LocalRecurrenceRepository(),
    exceptions,
    memories,
    reminders,
  );
  await series.load();
  return _Controllers(memories, series, exceptions);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a plain record is saved as a row and owns no series', () async {
    final env = await _controllers();

    final outcome = await env.saver.persist(
      _draft(savedAt: DateTime(2026, 3, 10, 12), body: 'Купить хлеб'),
      existing: null,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: null,
    );

    expect(outcome.created, isTrue);
    expect(outcome.seriesId, isNull);
    expect(env.memories.items.single.body, 'Купить хлеб');
    expect(env.series.state, isEmpty);
  });

  test('a new repeating record starts a series', () async {
    final env = await _controllers();

    final outcome = await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 3, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 99900,
        paymentCategory: PaymentCategory.subscription.name,
      ),
      existing: null,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: null,
    );

    expect(outcome.seriesId, isNotNull);
    final started = env.series.state.single;
    expect(started.frequency, RecurrenceFrequency.monthly);
    expect(started.template.amountMinor, 99900);
  });

  test('editing one occurrence writes an override, not a second row', () async {
    final env = await _controllers();

    await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 3, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 99900,
      ),
      existing: null,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: null,
    );
    final started = env.series.state.single;
    final rowsAfterStart = env.memories.items.length;

    // Июньское вхождение спроецировано и строки под собой не имеет.
    final june = occurrenceFromSeries(started, DateTime(2026, 6, 10));
    await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 6, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 120000,
        memoryDate: DateTime(2026, 6, 10),
      ),
      existing: june,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: DateTime(2026, 6, 10),
    );

    expect(env.memories.items, hasLength(rowsAfterStart));
    final override = env.exceptions.state.single;
    expect(override.occurrenceDate, DateTime(2026, 6, 10));
    expect(override.item?.amountMinor, 120000);
    // Шаблон серии правку одного вхождения не перенимает.
    expect(env.series.state.single.template.amountMinor, 99900);
  });

  test('this-and-future edit splits the series instead of one occurrence',
      () async {
    final env = await _controllers();

    await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 3, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 99900,
      ),
      existing: null,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: null,
    );
    final started = env.series.state.single;
    final june = occurrenceFromSeries(started, DateTime(2026, 6, 10));

    await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 6, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 150000,
        memoryDate: DateTime(2026, 6, 10),
      ),
      existing: june,
      refreshSeriesTemplate: false,
      editFutureOccurrences: true,
      originalOccurrenceDate: DateTime(2026, 6, 10),
    );

    expect(env.series.state.length, greaterThan(1));
  });

  test('subscription term is written only when the series itself is touched',
      () async {
    final env = await _controllers();

    final outcome = await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 3, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 99900,
        paymentCategory: PaymentCategory.subscription.name,
        subscriptionTermMonths: 3,
        subscriptionTermDirty: true,
      ),
      existing: null,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: null,
    );

    final started = env.series.state.single;
    expect(outcome.seriesId, started.id);
    expect(started.subscriptionEndDate, DateTime(2026, 5, 10));

    // Правка одного вхождения серию не трогает, значит и срок не переписывает.
    final april = occurrenceFromSeries(started, DateTime(2026, 4, 10));
    await env.saver.persist(
      _draft(
        savedAt: DateTime(2026, 4, 10, 12),
        type: MemoryType.payment,
        repeatRule: RecurrenceFrequency.monthly.name,
        amountMinor: 99900,
        paymentCategory: PaymentCategory.subscription.name,
        memoryDate: DateTime(2026, 4, 10),
        subscriptionTermMonths: 12,
        subscriptionTermDirty: true,
      ),
      existing: april,
      refreshSeriesTemplate: false,
      editFutureOccurrences: false,
      originalOccurrenceDate: DateTime(2026, 4, 10),
    );

    expect(
      env.series.state
          .singleWhere((item) => item.id == started.id)
          .subscriptionEndDate,
      DateTime(2026, 5, 10),
    );
  });
}
