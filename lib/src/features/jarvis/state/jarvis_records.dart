import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_feed/home_feed.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import 'jarvis_outcome.dart';

/// Джарвис и записи: завести, отметить, перенести, убрать в архив, найти.
///
/// Всё идёт теми же путями, что и с экранов: запись заводится контроллером
/// записей, повтор — серией, правка вхождения повтора — переопределением.
/// Своих способов менять данные у Джарвиса нет.
class JarvisRecords {
  const JarvisRecords(this._ref);

  final Ref _ref;

  MemoryItemsController get _items =>
      _ref.read(memoryItemsControllerProvider.notifier);

  RecurrenceSeriesController get _series =>
      _ref.read(recurrenceSeriesControllerProvider.notifier);

  MemoryItemCommands get _commands => _ref.read(memoryItemCommandsProvider);

  /// Заводит готовые дела: у каждого есть день, а время есть или не нужно.
  Future<JarvisOutcome> create(
    List<ParsedTask> tasks, {
    required String transcript,
    required DateTime now,
  }) async {
    final created = <MemoryItem>[];
    final repeats = <String, RecurrenceFrequency>{};
    final lengths = <String, int>{};
    final seriesIds = <String>[];
    for (final (index, task) in tasks.indexed) {
      final item =
          _itemFor(task, transcript: transcript, now: now, index: index);
      await _items.add(item);
      created.add(item);
      final length = task.durationMinutes;
      if (length != null && item.timeMinutes != null) lengths[item.id] = length;
      final frequency = _frequencyOf(task.repeat);
      if (frequency != null && !item.isUndated) {
        final series = await _series.setFrequency(item, frequency);
        seriesIds.add(series.id);
        repeats[item.id] = frequency;
      }
    }
    final last = created.last;
    return JarvisOutcome(
      JarvisReplies.created(created, now, repeats: repeats, lengths: lengths),
      link: last.isUndated
          ? const OpenPlace(JarvisPlace.notes)
          : OpenPlace(JarvisPlace.day, date: last.memoryDate),
      mentioned: last,
      undo: () async {
        for (final id in seriesIds) {
          await _series.deleteSeries(id);
        }
        for (final item in created) {
          if (_items.items.any((row) => row.id == item.id)) {
            await _items.delete(item.id);
          }
        }
      },
    );
  }

  /// Записка без даты.
  Future<JarvisOutcome> createNote(String text, DateTime now) async {
    final note = _itemFor(
      ParsedTask(title: text),
      transcript: text,
      now: now,
      index: 0,
    );
    await _items.add(note);
    return JarvisOutcome(
      JarvisReplies.note(text),
      link: const OpenPlace(JarvisPlace.notes),
      mentioned: note,
      undo: () => _items.delete(note.id),
    );
  }

  /// Отметить, вернуть в работу, убрать в архив, вернуть из архива,
  /// перенести. [mentioned] — запись, о которой только что говорили.
  Future<JarvisOutcome> change(
    ChangeRecord command, {
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    final target =
        command.query.isEmpty ? fresh(mentioned, now) : _find(command, now);
    if (target == null) {
      return JarvisOutcome(command.query.isEmpty
          ? JarvisReplies.nothingMentioned(command.change)
          : JarvisReplies.notFound(command.query));
    }
    return changeItem(target, command, now: now);
  }

  /// Отметить, вернуть, убрать в архив, вернуть из архива или перенести
  /// уже найденную запись — правилами или нейросетью.
  Future<JarvisOutcome> changeItem(
    MemoryItem target,
    ChangeRecord command, {
    required DateTime now,
  }) async {
    final MemoryItem result;
    switch (command.change) {
      case RecordChange.complete:
        if (target.isDone) return _already(target, 'уже выполнено');
        result = target.copyWith(status: MemoryStatus.done);
        await _commands.toggleDone(target);
      case RecordChange.reopen:
        if (!target.isDone) return _already(target, 'и так в работе');
        result = target.copyWith(status: MemoryStatus.active);
        await _commands.toggleDone(target);
      case RecordChange.archive:
        result = target.copyWith(status: MemoryStatus.archived);
        await _commands.archive(target);
      case RecordChange.restore:
        result = target.copyWith(status: MemoryStatus.active);
        await _commands.restore(target);
      case RecordChange.move:
        result = movedMemoryItem(
          target,
          date: command.date,
          minutes: command.minutes,
          now: now,
        );
        await _commands.save(result, original: target);
    }
    return JarvisOutcome(
      JarvisReplies.changed(command.change, result, now),
      link: result.isUndated || result.isArchived
          ? null
          : OpenPlace(JarvisPlace.day, date: result.memoryDate),
      mentioned: result,
      // Вхождение повтора возвращается переопределением по исходной дате,
      // обычная запись — своей прежней строкой.
      undo: () => _commands.save(target, original: target),
    );
  }

  /// «Когда у меня стоматолог».
  JarvisOutcome when(String query, DateTime now) {
    final found = findRecordsByWords(_living(now), query, now: now);
    if (found.isEmpty) return JarvisOutcome(JarvisReplies.notFound(query));
    final item = found.first;
    return JarvisOutcome(
      JarvisReplies.when(item, now),
      link: item.isUndated
          ? const OpenPlace(JarvisPlace.notes)
          : OpenPlace(JarvisPlace.day, date: item.memoryDate),
      mentioned: item,
    );
  }

  /// Поиск в ленте. Лента ищет по точным словам, поэтому ей отдаются основы:
  /// «врача» в ленте не нашло бы «Врач».
  JarvisOutcome search(String query, DateTime now) {
    final found = findRecordsByWords(_living(now), query, now: now);
    final feed = _ref.read(feedViewProvider.notifier);
    feed.selectSection(FeedSection.day);
    if (!_ref.read(feedViewProvider).searching) feed.toggleSearch();
    feed.search(searchStems(query).join(' '));
    return JarvisOutcome(
      JarvisReplies.searched(query, found.length),
      open: found.isEmpty ? null : const OpenPlace(JarvisPlace.feed),
    );
  }

  /// Записи календаря с [from] по [to] включительно — с повторами.
  List<MemoryItem> between(DateTime from, DateTime to) => [
        for (var day = DateTime(from.year, from.month, from.day);
            !day.isAfter(to);
            day = DateTime(day.year, day.month, day.day + 1))
          ..._ref.read(memoryItemsForDayProvider(day)),
      ];

  /// Записи и записки по словам, самые вероятные первыми.
  List<MemoryItem> find(String query, DateTime now) =>
      findRecordsByWords(_living(now), query, now: now);

  /// Запись по номеру — живая или в архиве: номер нейросеть берёт из
  /// списка дней или поиска.
  MemoryItem? byId(String id, DateTime now) {
    for (final item in [..._living(now), ...archived()]) {
      if (item.id == id) return fresh(item, now);
    }
    return null;
  }

  /// Записки без даты.
  List<MemoryItem> notes(DateTime now) => [
        for (final item in _living(now))
          if (item.isUndated) item,
      ];

  /// Архив — убранные последними первыми.
  List<MemoryItem> archived() => [..._ref.read(archivedMemoryItemsProvider)]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  MemoryItem _itemFor(
    ParsedTask task, {
    required String transcript,
    required DateTime now,
    required int index,
  }) {
    final date = task.date;
    final day = date ?? now;
    final suffix = index == 0 ? '' : '_$index';
    return MemoryItem(
      id: '${now.microsecondsSinceEpoch}$suffix',
      type: MemoryType.note,
      title: memoryTitleFromRecord(task.title, MemoryType.note, 'ru'),
      // Карточка дела: куда, что сделать, срочность — строками таблицы. По
      // строке «Куда» Джарвис потом прокладывает путь.
      body: taskCard(task),
      priority: task.urgent ? 1 : 0,
      memoryDate: DateTime(day.year, day.month, day.day),
      timeMinutes: date == null ? null : task.minutes,
      endMinutes: date == null || task.minutes == null
          ? null
          : _endOf(task.minutes!, task.durationMinutes),
      remindAt:
          date == null ? null : defaultReminderAt(date, task.minutes, now: now),
      createdAt: now,
      updatedAt: now,
      transcript: transcript,
      isUndated: date == null,
    );
  }

  /// Конец дела по его длительности — в пределах того же дня.
  static int _endOf(int start, int? length) =>
      (start + (length ?? _defaultLength)).clamp(start, 24 * 60 - 1);

  /// Длительность дела, если её не назвали. Без конца табличка на шкале дня
  /// была наименьшей, в четверть часа, — узкой (отзыв владельца 11 октября
  /// 2026): полчаса.
  static const _defaultLength = 30;

  static RecurrenceFrequency? _frequencyOf(PhraseRepeat? repeat) =>
      switch (repeat?.kind) {
        PhraseRepeatKind.monthly => RecurrenceFrequency.monthly,
        PhraseRepeatKind.yearly => RecurrenceFrequency.yearly,
        _ => null,
      };

  JarvisOutcome _already(MemoryItem item, String state) => JarvisOutcome(
        '«${item.title}» $state.',
        mentioned: item,
      );

  MemoryItem? _find(ChangeRecord command, DateTime now) {
    final pool = command.change == RecordChange.restore
        ? _ref.read(archivedMemoryItemsProvider)
        : _living(now);
    final found = findRecordsByWords(pool, command.query, now: now);
    return found.isEmpty ? null : found.first;
  }

  /// Та же запись, но такой, какой она лежит сейчас: её могли поменять с
  /// экрана, пока шёл разговор.
  MemoryItem? fresh(MemoryItem? item, DateTime now) {
    if (item == null) return null;
    return _ref.read(memoryItemByIdProvider(item.id)) ?? item;
  }

  /// Записи, о которых можно говорить: строки хранилища без архива и
  /// вхождения повторов за месяц назад и год вперёд.
  List<MemoryItem> _living(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final projected = _ref.read(recurrenceItemsForRangeProvider(
      RecurrenceRange(
        DateTime(today.year, today.month - 1, today.day),
        DateTime(today.year + 1, today.month, today.day),
      ),
    ));
    return [
      for (final item in _items.items)
        if (!item.isArchived) item,
      for (final item in projected)
        if (!item.isArchived) item,
    ];
  }
}
