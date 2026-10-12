import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/state/notification_providers.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import 'jarvis_outcome.dart';
import 'jarvis_records.dart';

/// Джарвис правит готовую запись: время, напоминание, будильник, название,
/// текст, длительность, срочность, повтор. Правка голосом без сети и правка
/// нейросетью идут одним путём ([apply]) — с одним ответом и одной отменой.
class JarvisRecordEdits {
  const JarvisRecordEdits(this._ref, this._records);

  final Ref _ref;
  final JarvisRecords _records;

  RecurrenceSeriesController get _series =>
      _ref.read(recurrenceSeriesControllerProvider.notifier);

  MemoryItemCommands get _commands => _ref.read(memoryItemCommandsProvider);

  /// Правка голосом: запись по словам или та, о которой говорили.
  Future<JarvisOutcome> editRecord(
    EditRecord command, {
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    var edit = command.edit;
    MemoryItem? target;
    if (command.appendTo case final said?) {
      final split = _appendTarget(said, now);
      if (split == null) return JarvisOutcome(JarvisReplies.notFound(said));
      (target, edit) = (split.$1, RecordEdit(addText: split.$2));
    } else if (command.query.isEmpty) {
      target = _records.fresh(mentioned, now);
      if (target == null) {
        return const JarvisOutcome(JarvisReplies.whichRecord);
      }
    } else {
      target = _records.find(command.query, now).firstOrNull;
      if (target == null) {
        return JarvisOutcome(JarvisReplies.notFound(command.query));
      }
    }
    return apply(
      target,
      edit: edit,
      repeat: command.repeat,
      stopRepeat: command.stopRepeat,
      now: now,
    );
  }

  /// Поправить найденную запись: сначала поля, потом повтор, потом —
  /// сделано, архив или возврат. Одна просьба — один ответ и одна отмена.
  Future<JarvisOutcome> apply(
    MemoryItem target, {
    RecordEdit edit = const RecordEdit(),
    RecurrenceFrequency? repeat,
    bool stopRepeat = false,
    RecordChange? status,
    required DateTime now,
  }) async {
    final outcomes = <JarvisOutcome>[];
    var record = target;
    if (!edit.isEmpty) {
      outcomes.add(await this.edit(record, edit, now: now));
      record = outcomes.last.mentioned ?? record;
    }
    if (repeat != null || stopRepeat) {
      if (record.isUndated) {
        outcomes.add(const JarvisOutcome(JarvisReplies.undatedRepeat));
      } else {
        outcomes.add(await this.repeat(record, repeat, now: now));
        record = outcomes.last.mentioned ?? record;
      }
    }
    if (status != null) {
      outcomes.add(
          await _records.changeItem(record, ChangeRecord(status, query: ''), now: now));
    }
    return JarvisOutcome.merged(
        outcomes.map((outcome) => outcome.say).join(' '), outcomes);
  }

  /// «Допиши к дню рождения мамы купить торт»: название — самое длинное
  /// начало фразы, которое находит запись, остальное — текст.
  (MemoryItem, String)? _appendTarget(String said, DateTime now) {
    final words = said.split(RegExp(r'\s+'));
    for (var count = words.length - 1; count > 0; count--) {
      final query = recordQuery(words.take(count).join(' '));
      if (query.isEmpty) continue;
      final found = _records.find(query, now).firstOrNull;
      if (found != null) return (found, words.skip(count).join(' '));
    }
    return null;
  }

  /// Поправить запись одной правкой — с одной отменой.
  Future<JarvisOutcome> edit(
    MemoryItem target,
    RecordEdit edit, {
    required DateTime now,
  }) async {
    final sound = edit.alarm == true
        ? await _ref.read(notificationServiceProvider).defaultAlarmSound()
        : null;
    final result = editedMemoryItem(target, edit,
        now: now,
        alarmSound: sound == null ? null : (uri: sound.uri, name: sound.name));
    await _commands.save(result, original: target);
    final missedAlarm = edit.alarm == true && result.reminderSoundUri == null;
    return JarvisOutcome(
      missedAlarm
          ? '${JarvisReplies.edited(result, now)} ${JarvisReplies.noAlarm}'
          : JarvisReplies.edited(result, now),
      link: result.isUndated
          ? const OpenPlace(JarvisPlace.notes)
          : OpenPlace(JarvisPlace.day, date: result.memoryDate),
      mentioned: result,
      undo: () => _commands.save(target, original: target),
    );
  }

  /// Повторять запись каждый месяц или год; null — перестать. Путь тот же,
  /// что у редактора записи: серия. Снятый повтор отмена заводит заново, но
  /// правки отдельных повторов, как и в редакторе, при снятии пропадают.
  Future<JarvisOutcome> repeat(
    MemoryItem target,
    RecurrenceFrequency? frequency, {
    required DateTime now,
  }) async {
    final seriesId = target.seriesId;
    final before = seriesId == null
        ? null
        : _ref
            .read(recurrenceSeriesControllerProvider)
            .where((series) => series.id == seriesId)
            .firstOrNull;
    final link = OpenPlace(JarvisPlace.day, date: target.memoryDate);
    if (frequency != null) {
      final series = await _series.setFrequency(target, frequency);
      final repeated = target.copyWith(seriesId: series.id);
      final previous = before?.frequency;
      return JarvisOutcome(
        JarvisReplies.repeating(target, frequency),
        link: link,
        mentioned: repeated,
        undo: previous == null
            ? () => _series.clearFrequency(repeated)
            : () => _series.setFrequency(target, previous),
      );
    }
    if (before == null) {
      return JarvisOutcome(JarvisReplies.notRepeating(target));
    }
    await _series.clearFrequency(target);
    // Запись снова живёт строкой — с номером той, из которой вырос повтор.
    final single = _ref.read(memoryItemByIdProvider(before.originItemId));
    return JarvisOutcome(
      JarvisReplies.notRepeating(target),
      link: link,
      mentioned: single,
      undo: single == null
          ? null
          : () => _series.setFrequency(single, before.frequency),
    );
  }
}
