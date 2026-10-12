import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/calendar.dart';
import '../../finance/finance.dart';
import '../../memory_items/memory_items.dart';
import '../../shift_schedules/shift_schedules.dart';
import 'jarvis_outcome.dart';
import 'jarvis_records.dart';

/// Ответы Джарвиса на вопросы: о делах, сменах, праздниках, деньгах и
/// курсах. Ничего не меняют — только читают то, что уже показывают экраны,
/// из тех же провайдеров.
class JarvisAnswers {
  const JarvisAnswers(this._ref, this._records, {required this.address});

  final Ref _ref;
  final JarvisRecords _records;

  /// Обращение в начале рассказа о делах: «Сэр, на завтра…».
  final String address;

  JarvisOutcome agenda(AskAgenda command, DateTime now) {
    if (command.important) {
      return JarvisOutcome(
        AgendaSpeech.important(
          _records.between(command.from, command.to),
          label: command.label,
          address: address,
        ),
        link: command.isOneDay
            ? OpenPlace(JarvisPlace.day, date: command.from)
            : const OpenPlace(JarvisPlace.calendar),
      );
    }
    if (command.isOneDay) {
      final day = command.from;
      return JarvisOutcome(
        AgendaSpeech.day(
          _ref.read(memoryItemsForDayProvider(day)),
          day: day,
          now: now,
          label: command.label,
          address: address,
        ),
        link: OpenPlace(JarvisPlace.day, date: day),
      );
    }
    final items = _records.between(command.from, command.to);
    return JarvisOutcome(
      AgendaSpeech.range(items, now: now, label: command.label, address: address),
      link: const OpenPlace(JarvisPlace.calendar),
    );
  }

  /// Прошлое календаря — со сделанным или только несделанное.
  JarvisOutcome history(AskHistory command, DateTime now) {
    final oneDay = command.from == command.to;
    return JarvisOutcome(
      AgendaSpeech.history(
        _records.between(command.from, command.to),
        label: command.label,
        now: now,
        unfinished: command.unfinished,
        important: command.important,
      ),
      link: oneDay
          ? OpenPlace(JarvisPlace.day, date: command.from)
          : const OpenPlace(JarvisPlace.calendar),
    );
  }

  /// Деньги за прошлое — только из журнала финансов Ежедневника.
  JarvisOutcome financeHistory(AskFinanceHistory command, DateTime now) =>
      JarvisOutcome(
        financeHistoryReply(command, _ref.read(financeControllerProvider), now),
        link: const OpenPlace(JarvisPlace.finance),
      );

  JarvisOutcome undated() => JarvisOutcome(
        AgendaSpeech.undated(_ref.read(undatedNotesProvider), address: address),
        link: const OpenPlace(JarvisPlace.notes),
      );

  /// Праздники дня — даже если в календаре они скрыты: человек спросил сам.
  JarvisOutcome holidays(AskHolidays command, DateTime now) {
    final titles = holidaysOn(command.day);
    return JarvisOutcome(
      holidaysReply(titles: titles, dayLabel: spokenDay(command.day, now)),
      link: titles.isEmpty
          ? null
          : OpenPlace(JarvisPlace.holidays, date: command.day),
    );
  }

  /// Названия праздников дня; международные дни — если они включены.
  List<String> holidaysOn(DateTime day) => [
        for (final holiday in _ref
            .read(holidayCalendarServiceProvider)
            .holidaysForDate(day,
                withObservances: _ref.read(appObservancesProvider)))
          holiday.titleRu,
      ];

  /// Есть ли у владельца хоть один включённый график смен.
  bool get hasShiftSchedules => _schedules.isNotEmpty;

  /// По каким графикам день рабочий. Отпуск — не рабочий день.
  List<String> shiftsOn(DateTime day) => workingShifts(_schedules, day);

  List<ShiftSchedule> get _schedules => [
        for (final schedule in _ref.read(shiftSchedulesControllerProvider))
          if (schedule.isEnabled) schedule,
      ];

  JarvisOutcome shift(AskShift command, DateTime now) {
    var day = command.day;
    if (command.findNext && hasShiftSchedules) {
      // Ближайшая смена или выходной — не дальше двух месяцев: дальше
      // графики не ведут.
      bool found(DateTime day) => shiftsOn(day).isEmpty == command.dayOff;
      for (var i = 0; i < 62 && !found(day); i++) {
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    return JarvisOutcome(
      shiftReply(
        command,
        working: shiftsOn(day),
        hasSchedules: hasShiftSchedules,
        dayLabel: spokenWhen(day, now),
      ),
      link: hasShiftSchedules ? null : const OpenPlace(JarvisPlace.shifts),
    );
  }

  /// Сколько смен в месяце — по графикам. Часов в графиках нет, и Джарвис
  /// говорит об этом, а не выдумывает.
  JarvisOutcome shiftCount(AskShiftCount command, DateTime now) {
    if (!hasShiftSchedules) {
      return const JarvisOutcome(
        'Графиков смен у вас нет. Их можно завести в настройках.',
        link: OpenPlace(JarvisPlace.shifts),
      );
    }
    final month = command.month;
    final today = DateTime(now.year, now.month, now.day);
    var count = 0;
    for (var day = month;
        day.month == month.month && !(command.pastOnly && day.isAfter(today));
        day = DateTime(day.year, day.month, day.day + 1)) {
      if (shiftsOn(day).isNotEmpty) count++;
    }
    return JarvisOutcome(
      shiftCountReply(command, count: count, now: now),
      link: const OpenPlace(JarvisPlace.shifts),
    );
  }

  /// Ближайшее дело со временем — сегодня позже или в ближайшие две недели.
  JarvisOutcome next(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final minute = now.hour * 60 + now.minute;
    for (var offset = 0; offset < 14; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      final timed = [
        for (final item in _ref.read(memoryItemsForDayProvider(day)))
          if (item.timeMinutes case final start?
              when !item.isDone && (offset > 0 || start >= minute))
            item,
      ]..sort((left, right) => left.timeMinutes!.compareTo(right.timeMinutes!));
      if (timed.isNotEmpty) {
        final item = timed.first;
        return JarvisOutcome(
          FreeTime.nextReply(item, now),
          link: OpenPlace(JarvisPlace.day, date: day),
          mentioned: item,
        );
      }
    }
    return JarvisOutcome(FreeTime.nextReply(null, now));
  }

  /// Свободное время: окна дня или свободные дни периода.
  JarvisOutcome free(AskFree command, DateTime now) {
    if (command.isOneDay) {
      final day = command.from;
      final items = _ref.read(memoryItemsForDayProvider(day));
      return JarvisOutcome(
        FreeTime.dayReply(
          label: command.label,
          windows: FreeTime.windows(items, day: day, now: now),
          shifts: shiftsOn(day),
          timed: items.where((item) => item.timeMinutes != null).length,
        ),
        link: OpenPlace(JarvisPlace.day, date: day),
      );
    }
    return JarvisOutcome(
      FreeTime.rangeReply(
        label: command.label,
        days: [
          for (var day = command.from;
              !day.isAfter(command.to);
              day = DateTime(day.year, day.month, day.day + 1))
            (
              day: day,
              timed: _ref
                  .read(memoryItemsForDayProvider(day))
                  .where((item) => item.timeMinutes != null && !item.isDone)
                  .length,
              shift: shiftsOn(day).isNotEmpty,
            ),
        ],
        now: now,
      ),
      link: const OpenPlace(JarvisPlace.calendar),
    );
  }

  /// Будильники Ежедневника на две недели вперёд: напоминания с мелодией и
  /// будильники графиков смен.
  JarvisOutcome alarms(DateTime now) {
    final found = <AlarmMention>[];
    final today = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 14; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      for (final item in _ref.read(memoryItemsForDayProvider(day))) {
        final at = item.remindAt;
        if (item.reminderSoundUri != null && wantsReminder(item, now: now)) {
          found.add((at: at!, what: item.title));
        }
      }
    }
    for (final schedule in _schedules) {
      for (final (slot, alarm) in schedule.alarms.indexed) {
        for (final at in shiftAlarmTimes(schedule, alarm, slot,
            now: now, horizonDays: 14)) {
          found.add((at: at, what: 'смена, ${schedule.organizationName}'));
        }
      }
    }
    return JarvisOutcome(
      alarmsReply(found, now),
      link: found.isEmpty ? null : const OpenPlace(JarvisPlace.calendar),
    );
  }

  /// Итог месяца в валюте журнала, открытого в финансах: журналы валют
  /// независимы и друг к другу не сводятся.
  JarvisOutcome finance(AskFinance command, DateTime now) {
    final currency = _ref.read(financeCurrencyProvider);
    final entries = [
      for (final entry in _ref.read(financeControllerProvider))
        if (entry.currencyCode == currency &&
            entry.kind == command.kind &&
            entry.occurredOn.year == command.month.year &&
            entry.occurredOn.month == command.month.month)
          entry,
    ];
    final summary = FinanceSummary.forEntries(entries);
    final total = command.kind == FinanceEntryKind.expense
        ? summary.expense
        : summary.income;
    return JarvisOutcome(
      financeReply(command,
          total: total.toString(), currency: currency, now: now),
      link: const OpenPlace(JarvisPlace.finance),
    );
  }

  /// Курс ЦБ. Без сети берётся сохранённый курс; нет и его — честно об этом.
  Future<JarvisOutcome> currency(ConvertCurrency command, DateTime now) async {
    final rates = await _ref.read(exchangeRateRepositoryProvider).load();
    if (rates == null) {
      return const JarvisOutcome(
          'Не смог получить курс ЦБ: нет связи, а сохранённых курсов ещё нет.');
    }
    final result = rates.convert(
      amount: command.amount,
      from: command.from,
      to: command.to,
    );
    if (result == null) return const JarvisOutcome('Курса этой валюты у ЦБ нет.');
    return JarvisOutcome(
      currencyReply(command, result: result, ratesDate: rates.date, now: now),
    );
  }
}
