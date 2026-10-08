import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_answers.dart';
import 'jarvis_outcome.dart';
import 'jarvis_places.dart';
import 'jarvis_records.dart';
import 'jarvis_settings_actions.dart';

/// Кто что исполняет. Команда от правил и команда от нейросети идут сюда
/// одинаково — у Джарвиса один набор рук.
class JarvisExecutor {
  factory JarvisExecutor(Ref ref, {required String address}) {
    final records = JarvisRecords(ref);
    return JarvisExecutor._(
      ref,
      records,
      JarvisAnswers(ref, records, address: address),
      JarvisSettingsActions(ref),
    );
  }

  JarvisExecutor._(this._ref, this._records, this._answers, this._settings);

  final Ref _ref;
  final JarvisRecords _records;

  /// Записи — для нейросети: она видит их, прежде чем отвечать о делах.
  JarvisRecords get records => _records;
  final JarvisAnswers _answers;
  final JarvisSettingsActions _settings;

  /// Выставляет странице нужную закладку или месяц до перехода на неё.
  void prepare(OpenPlace target) => preparePlace(_ref, target);

  /// Заводит дела, которым уже ничего не нужно уточнять. Дело без дня
  /// становится запиской.
  Future<JarvisOutcome> create(
    List<ParsedTask> tasks, {
    required String transcript,
    required DateTime now,
  }) =>
      _records.create(tasks, transcript: transcript, now: now);

  Future<JarvisOutcome> run(
    JarvisCommand command, {
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    return switch (command) {
      JarvisSay(:final text) => JarvisOutcome(text),
      UndoLast() => const JarvisOutcome(JarvisReplies.nothingToUndo),
      OpenPlace() =>
        JarvisOutcome(JarvisReplies.opened(command, now), open: command),
      AskAgenda() => _answers.agenda(command, now),
      AskUndated() => _answers.undated(),
      AskWhen(:final query) => _records.when(query, now),
      AskShift() => _answers.shift(command, now),
      AskHolidays() => _answers.holidays(command, now),
      AskFinance() => _answers.finance(command, now),
      AskBrain() => const JarvisOutcome(JarvisReplies.needsBrain),
      CreateTasks(:final tasks, :final transcript) =>
        await create(tasks, transcript: transcript, now: now),
      CreateNote(:final text) => await _records.createNote(text, now),
      ChangeRecord() =>
        await _records.change(command, mentioned: mentioned, now: now),
      SearchRecords(:final query) => _records.search(query, now),
      Calculate() => JarvisOutcome(calculationReply(command)),
      ConvertUnits() => JarvisOutcome(unitReply(command)),
      ConvertCurrency() => await _answers.currency(command, now),
      AddFinanceEntry() => await _settings.addFinance(command, now),
      SwitchSetting() => await _settings.toggle(command),
      ChangeTheme() => await _settings.theme(command),
    };
  }
}
