import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

import 'jarvis_brain_tools.dart';
import 'jarvis_executor.dart';
import 'jarvis_online.dart';
import 'jarvis_outcome.dart';

/// Нейросеть Джарвиса: свободная речь, советы, ответы на любые вопросы.
///
/// Видит она весь Ежедневник, кроме «Аккаунтов», а действует теми же руками,
/// что и правила: записи, деньги и страницы — точными функциями
/// ([JarvisBrainTools]), остальное — `run_command`, короткой командой разбору
/// фраз. Своих способов менять данные у нейросети нет: всё идёт через
/// исполнителя, с той же отменой.
class JarvisBrain {
  JarvisBrain({
    required GigaChatClient client,
    required JarvisExecutor executor,
    required JarvisOnline online,
  })  : _client = client,
        _executor = executor,
        _online = online;

  final GigaChatClient _client;
  final JarvisExecutor _executor;
  final JarvisOnline _online;
  late final _tools = JarvisBrainTools(_executor);

  /// Разговор помнится полчаса и не дольше двенадцати реплик: дальше он уже
  /// не помогает понять просьбу, а только дорожает.
  static const _memory = Duration(minutes: 30);
  static const _keptReplies = 12;

  /// Обращений к функциям за один ответ. Полгода прошлого — это пять
  /// обращений по шесть недель, и ещё одно остаётся на что-нибудь другое.
  static const _maxCalls = 6;

  final _history = <Map<String, dynamic>>[];
  DateTime? _lastAsked;

  /// Забыть разговор: следующий вопрос — с чистого листа.
  void forget() {
    _history.clear();
    _lastAsked = null;
  }

  /// Ответ нейросети для разговора. Спросила сама («Записать, сэр?») —
  /// короткий ответ уходит ей же, а не разбору фраз, где «да» — реплика, а
  /// «давай» — дело. Нет связи — Джарвис говорит об этом прямо или
  /// отвечает тем, что ему велели помнить.
  Future<JarvisOutcome> answer(
    String text, {
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    try {
      final outcome = await ask(text, mentioned: mentioned, now: now);
      if (!outcome.say.trim().endsWith('?')) return outcome;
      return outcome.awaiting(
          (said, now) => answer(said, mentioned: mentioned, now: now));
    } on GigaChatException catch (failure) {
      final recalled = failure.offline ? _executor.recall(text) : null;
      return recalled ?? JarvisOutcome(failure.message);
    }
  }

  /// Спрашивает нейросеть. Бросает [GigaChatException], если она не ответила.
  Future<JarvisOutcome> ask(
    String text, {
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    final last = _lastAsked;
    if (last == null || now.difference(last) > _memory) _history.clear();
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': jarvisBrainInstructions(now, facts: _executor.facts),
      },
      ..._history,
      {'role': 'user', 'content': text},
    ];
    final outcomes = <JarvisOutcome>[];
    var said = '';
    var cut = false;
    // Последний запрос — уже без права на функцию: ответ словами нужен
    // всегда, даже если нейросеть потратила все обращения к данным.
    for (var call = 0; call <= _maxCalls; call++) {
      final message = await _client.chat(messages,
          functions: JarvisBrainFunctions.specs,
          callFunctions: call < _maxCalls);
      final function = message['function_call'];
      if (function is! Map || call == _maxCalls) {
        said = message['content'] as String? ?? '';
        cut = message['finish_reason'] == 'length';
        break;
      }
      final name = '${function['name'] ?? ''}';
      final result = await _run(name, _arguments(function['arguments']),
          outcomes: outcomes, mentioned: mentioned, now: now);
      messages
        ..add({
          'role': 'assistant',
          'content': message['content'] ?? '',
          'function_call': function,
          if (message['functions_state_id'] != null)
            'functions_state_id': message['functions_state_id'],
        })
        ..add(
            {'role': 'function', 'name': name, 'content': jsonEncode(result)});
    }
    _lastAsked = now;
    final reply = cleanBrainReply(said, cut: cut);
    final spoken = reply.isNotEmpty
        ? reply
        : outcomes.map((outcome) => outcome.say).join(' ');
    _history
      ..add({'role': 'user', 'content': text})
      ..add({'role': 'assistant', 'content': spoken});
    while (_history.length > _keptReplies) {
      _history.removeAt(0);
    }
    return JarvisOutcome.merged(spoken, outcomes);
  }

  Future<Object?> _run(
    String name,
    Map<String, dynamic> arguments, {
    required List<JarvisOutcome> outcomes,
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    final tooled = await _tools.run(name, arguments,
        outcomes: outcomes, mentioned: mentioned, now: now);
    if (tooled != null) return tooled;
    switch (name) {
      case JarvisBrainFunctions.runCommand:
        final phrase = '${arguments['phrase'] ?? ''}';
        final outcome = await _command(phrase, mentioned: mentioned, now: now);
        if (outcome == null) {
          return {'error': 'Команда не распознана. Скажи её проще.'};
        }
        outcomes.add(outcome);
        return {'result': outcome.say};
      case JarvisBrainFunctions.listFinance:
        final period = _period(arguments);
        if (period == null) return _needsDates;
        return financeForBrain(_executor.finance,
            from: period.from, to: period.to);
      case JarvisBrainFunctions.rememberFact:
        final outcome = await _executor.run(
            RememberFact('${arguments['fact'] ?? ''}'),
            mentioned: mentioned,
            now: now);
        outcomes.add(outcome);
        return {'result': outcome.say};
      case JarvisBrainFunctions.forgetFact:
        final outcome = await _executor.run(
            ForgetFact('${arguments['fact'] ?? ''}'),
            mentioned: mentioned,
            now: now);
        outcomes.add(outcome);
        return {'result': outcome.say};
      case JarvisBrainFunctions.listDays:
        final period = _period(arguments);
        if (period == null) return _needsDates;
        return _days(period.from, period.to);
      case JarvisBrainFunctions.weather:
        return _online.weather(
          place: arguments['place'] as String?,
          day: parseBrainDate(arguments['date']),
          now: now,
        );
      case JarvisBrainFunctions.wikiLookup:
        return _online.lookup('${arguments['query'] ?? ''}');
      case JarvisBrainFunctions.news:
        return _online.news(arguments['topic'] as String?);
      case JarvisBrainFunctions.findRecords:
        return [
          for (final item in _executor.records
              .find('${arguments['query'] ?? ''}', now)
              .take(15))
            recordForBrain(item),
        ];
    }
    return {'error': 'Такой функции нет'};
  }

  /// Дни для нейросети — не больше шести недель за раз: ответ читается
  /// моделью целиком, и длинный список только дорожает.
  List<Map<String, Object?>> _days(DateTime from, DateTime to) {
    final answers = _executor.answers;
    final days = <Map<String, Object?>>[];
    for (var day = from;
        !day.isAfter(to) && days.length < 42;
        day = DateTime(day.year, day.month, day.day + 1)) {
      days.add(dayForBrain(
        day,
        records: _executor.records.between(day, day),
        shifts: answers.shiftsOn(day),
        holidays: answers.holidaysOn(day),
        hasShiftSchedules: answers.hasShiftSchedules,
      ));
    }
    return days;
  }

  /// Команда нейросети исполняется так же, как сказанная человеком. Уточнять
  /// у нейросети «во сколько?» некому: дело без дня становится запиской, без
  /// времени — делом на весь день.
  Future<JarvisOutcome?> _command(
    String phrase, {
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    final command = const JarvisCommandParser().parse(phrase, now);
    switch (command) {
      case null || AskBrain() || UndoLast():
        return null;
      case CreateTasks(:final tasks, :final transcript):
        return _executor.create(
          [
            for (final task in tasks)
              task.need == TaskNeed.time ? task.copyWith(allDay: true) : task,
          ],
          transcript: transcript,
          now: now,
        );
      default:
        return _executor.run(command, mentioned: mentioned, now: now);
    }
  }

  /// Период из вызова функции: `from` и `to` как YYYY-MM-DD; без `to` —
  /// один день.
  static ({DateTime from, DateTime to})? _period(
      Map<String, dynamic> arguments) {
    final from = parseBrainDate(arguments['from']);
    final to = parseBrainDate(arguments['to']) ?? from;
    return from == null || to == null ? null : (from: from, to: to);
  }

  static const _needsDates = {'error': 'Нужны даты YYYY-MM-DD'};

  static Map<String, dynamic> _arguments(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return const {};
  }
}
