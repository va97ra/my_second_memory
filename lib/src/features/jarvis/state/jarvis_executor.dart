import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/finance.dart';
import 'jarvis_answers.dart';
import 'jarvis_facts.dart';
import 'jarvis_outcome.dart';
import 'jarvis_phone.dart';
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

  /// Смены и праздники — тоже для нейросети: «свободный день» без них не
  /// понять.
  JarvisAnswers get answers => _answers;
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
      AskAlarms() => _answers.alarms(now),
      AskMetroRoute(:final from, :final to) =>
        JarvisOutcome(MetroGuide.moscow.route(from, to)),
      AskHistory() => _answers.history(command, now),
      AskFinanceHistory() => _answers.financeHistory(command, now),
      RememberFact(:final fact) => await _remember(fact),
      ForgetFact(:final query) => await _forget(query),
      ListFacts() => JarvisOutcome(FactReplies.list(facts)),
      AskFinance() => _answers.finance(command, now),
      AskBrain(:final text) =>
        recall(text) ?? const JarvisOutcome(JarvisReplies.needsBrain),
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
      PhoneCommand() => await _ref.read(jarvisPhoneProvider).run(command),
    };
  }

  /// Журнал финансов — для нейросети: только то, что записано в Ежедневнике.
  List<FinanceEntry> get finance => _ref.read(financeControllerProvider);

  /// Что хозяин просил запомнить — для нейросети и для ответов без неё.
  List<String> get facts => _ref.read(jarvisFactsProvider);

  /// Ответ из запомненного: «что любит мама?» — «Вы говорили: мама любит
  /// белые розы». null — ничего подходящего.
  JarvisOutcome? recall(String question) {
    final fact = factFor(question, facts);
    return fact == null ? null : JarvisOutcome(FactReplies.answer(fact));
  }

  Future<JarvisOutcome> _remember(String fact) async {
    final memory = _ref.read(jarvisFactsProvider.notifier);
    await memory.add(fact);
    return JarvisOutcome(
      FactReplies.remembered(fact),
      undo: () async => memory.forget(fact),
    );
  }

  Future<JarvisOutcome> _forget(String query) async {
    final memory = _ref.read(jarvisFactsProvider.notifier);
    final forgotten = await memory.forget(query);
    if (forgotten == null) return const JarvisOutcome(FactReplies.unknown);
    return JarvisOutcome(
      FactReplies.forgotten(forgotten),
      undo: () => memory.add(forgotten),
    );
  }
}
