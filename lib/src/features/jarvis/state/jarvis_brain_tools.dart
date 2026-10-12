import 'package:ez_domain/ez_domain.dart';

import 'jarvis_executor.dart';
import 'jarvis_outcome.dart';

/// Руки и глаза нейросети в Ежедневнике — точные функции вместо фраз.
///
/// Исполняют их те же руки, что и правила ([JarvisExecutor]): запись
/// заводится тем же путём, что и с голоса, правится переносом и правкой
/// записи, деньги — тем же журналом, всё с той же отменой. Нейросеть лишь
/// понимает свободную речь и раскладывает её по полям (решение владельца
/// 12 октября 2026: «наговорил — а он сам решил, что куда расставить»).
class JarvisBrainTools {
  JarvisBrainTools(this._executor);

  final JarvisExecutor _executor;

  /// Что вернуть нейросети на вызов [name]; сделанное — в [outcomes].
  /// Null — это не функция инструментов.
  Future<Object?> run(
    String name,
    Map<String, dynamic> arguments, {
    required List<JarvisOutcome> outcomes,
    required MemoryItem? mentioned,
    required DateTime now,
  }) async {
    Future<Object?> done(Future<JarvisOutcome> action) async {
      final outcome = await action;
      outcomes.add(outcome);
      return {'result': outcome.say};
    }

    switch (name) {
      case JarvisBrainFunctions.createRecord:
        final task = _task(arguments);
        if (task == null) return {'error': 'Нужно название дела'};
        return done(_executor.create([task], transcript: task.title, now: now));
      case JarvisBrainFunctions.updateRecord:
        return _update(arguments, outcomes, now);
      case JarvisBrainFunctions.addFinance:
        final entry = _money(arguments, now);
        if (entry == null) return {'error': 'Нужна сумма больше нуля'};
        return done(_executor.run(entry, mentioned: mentioned, now: now));
      case JarvisBrainFunctions.openPage:
        final place = JarvisPlace.values.asNameMap()['${arguments['page']}'];
        if (place == null) return {'error': 'Такой страницы нет'};
        final page = OpenPlace(place, date: parseBrainDate(arguments['date']));
        return done(_executor.run(page, mentioned: mentioned, now: now));
      case JarvisBrainFunctions.listNotes:
        return [
          for (final item in _executor.records.notes(now))
            recordForBrain(item, textLimit: 4000),
        ];
      case JarvisBrainFunctions.listArchive:
        return [
          for (final item in _executor.records.archived().take(30))
            recordForBrain(item, textLimit: 600),
        ];
      case JarvisBrainFunctions.getSettings:
        return _executor.settings;
      case JarvisBrainFunctions.changeSetting:
        final command = _setting(arguments);
        if (command == null) {
          return {'error': 'Нужны setting и enabled, а сводке — time'};
        }
        return done(_executor.run(command, mentioned: mentioned, now: now));
      case JarvisBrainFunctions.lookAtScreen:
        // Только посмотреть: рассказ о странице без перехода на неё.
        final told = await _executor.run(const LookAtPage(),
            mentioned: mentioned, now: now);
        return {'screen': told.say};
    }
    return null;
  }

  /// Дело из полей: всё, что сказано о нём, — в карточку, а не в название.
  static ParsedTask? _task(Map<String, dynamic> arguments) {
    final title = _text(arguments['title']);
    if (title == null) return null;
    final date = parseBrainDate(arguments['date']);
    final minutes = date == null ? null : _clock(arguments['time']);
    return ParsedTask(
      title: capitalizeFirst(title),
      date: date,
      minutes: minutes,
      allDay: date != null && minutes == null,
      address: _text(arguments['address']),
      details: _text(arguments['todo']),
      urgent: arguments['urgent'] == true,
      durationMinutes: _number(arguments['duration_minutes'])?.round(),
      repeat: switch (arguments['repeat']) {
        'monthly' => const PhraseRepeat(PhraseRepeatKind.monthly),
        'yearly' => const PhraseRepeat(PhraseRepeatKind.yearly),
        _ => null,
      },
    );
  }

  /// Поправить запись тем же путём, что и правка голосом без сети.
  Future<Object?> _update(
    Map<String, dynamic> arguments,
    List<JarvisOutcome> outcomes,
    DateTime now,
  ) async {
    final target = _target(arguments, now);
    if (target is! MemoryItem) return target;
    final edit = RecordEdit(
      date: parseBrainDate(arguments['date']),
      minutes: _clock(arguments['time']),
      shiftMinutes: _number(arguments['shift_minutes'])?.round(),
      durationMinutes: _number(arguments['duration_minutes'])?.round(),
      title: _text(arguments['title']),
      addText: _text(arguments['add_text']),
      urgent: arguments['urgent'] is bool ? arguments['urgent'] as bool : null,
      reminderBefore: _number(arguments['remind_minutes_before'])?.round(),
      removeReminder: arguments['remove_reminder'] == true,
      alarm: arguments['alarm'] is bool ? arguments['alarm'] as bool : null,
    );
    final status = switch (arguments['status']) {
      'done' => RecordChange.complete,
      'active' => RecordChange.reopen,
      'archived' => RecordChange.archive,
      'restored' => RecordChange.restore,
      _ => null,
    };
    final repeat = arguments['repeat'];
    final frequency = switch (repeat) {
      'monthly' => RecurrenceFrequency.monthly,
      'yearly' => RecurrenceFrequency.yearly,
      _ => null,
    };
    final repeats = frequency != null || repeat == 'none';
    if (repeats && target.isUndated) {
      return {'error': 'У записки без даты повтора нет — сначала назначь день'};
    }
    if (edit.isEmpty && status == null && !repeats) {
      return {'error': 'Не названо, что поправить'};
    }
    final applied = await _executor.edits.apply(
      target,
      edit: edit,
      repeat: frequency,
      stopRepeat: repeat == 'none',
      status: status,
      now: now,
    );
    outcomes.add(applied);
    return {'result': applied.say};
  }

  /// Запись по номеру или по словам. Подходят несколько — нейросети
  /// список: выбрать по дню или переспросить хозяина.
  Object _target(Map<String, dynamic> arguments, DateTime now) {
    final id = _text(arguments['id']);
    if (id != null) {
      return _executor.records.byId(id, now) ??
          {'error': 'Записи с таким id нет'};
    }
    final query = _text(arguments['query']);
    if (query == null) return {'error': 'Нужен id или query'};
    // Повтор — одна запись, сколько бы месяцев он ни занимал: из его
    // вхождений остаётся ближайшее, как и у правил.
    final series = <String>{};
    final found = [
      for (final item in _executor.records.find(query, now))
        if (item.seriesId == null || series.add(item.seriesId!)) item,
    ];
    if (found.isEmpty) return {'error': 'Записи «$query» не нашёл'};
    if (found.length == 1) return found.single;
    return {
      'choose': [for (final item in found.take(5)) recordForBrain(item)],
      'hint': 'Подходят несколько — выбери id по дню или переспроси хозяина',
    };
  }

  /// Настройка из полей: у сводки со временем — время, иначе флажок.
  static JarvisCommand? _setting(Map<String, dynamic> arguments) {
    final setting = JarvisSwitch.values.asNameMap()['${arguments['setting']}'];
    if (setting == null) return null;
    final at = _clock(arguments['time']);
    final enabled = arguments['enabled'];
    final briefing = setting == JarvisSwitch.morningBriefing ||
        setting == JarvisSwitch.eveningBriefing;
    if (briefing && at != null && enabled != false) {
      return BriefingAt(
          evening: setting == JarvisSwitch.eveningBriefing, minutes: at);
    }
    return enabled is bool ? SwitchSetting(setting, enabled: enabled) : null;
  }

  /// Расход или доход из полей. Валюта — только известная журналу.
  static AddFinanceEntry? _money(Map<String, dynamic> arguments, DateTime now) {
    final amount = _number(arguments['amount']);
    if (amount == null || amount <= 0) return null;
    final code = _text(arguments['currency'])?.toUpperCase();
    return AddFinanceEntry(
      kind: arguments['kind'] == 'income'
          ? FinanceEntryKind.income
          : FinanceEntryKind.expense,
      amount: amount == amount.roundToDouble()
          ? amount.round().toString()
          : amount.toString(),
      date: parseBrainDate(arguments['date']) ??
          DateTime(now.year, now.month, now.day),
      currency: currencyWords.any((word) => word.code == code) ? code : null,
      category: capitalizeFirst(_text(arguments['category']) ?? ''),
    );
  }

  static String? _text(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

  /// «10:30» — минуты от полуночи.
  static int? _clock(Object? value) {
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch('${value ?? ''}'.trim());
    if (match == null) return null;
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    return hours < 24 && minutes < 60 ? hours * 60 + minutes : null;
  }
}
