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

  JarvisOutcome undated() => JarvisOutcome(
        AgendaSpeech.undated(_ref.read(undatedNotesProvider), address: address),
        link: const OpenPlace(JarvisPlace.notes),
      );

  /// Праздники дня — даже если в календаре они скрыты: человек спросил сам.
  JarvisOutcome holidays(AskHolidays command, DateTime now) {
    final holidays = _ref.read(holidayCalendarServiceProvider).holidaysForDate(
          command.day,
          withObservances: _ref.read(appObservancesProvider),
        );
    return JarvisOutcome(
      holidaysReply(
        titles: [for (final holiday in holidays) holiday.titleRu],
        dayLabel: spokenDay(command.day, now),
      ),
      link: holidays.isEmpty
          ? null
          : OpenPlace(JarvisPlace.holidays, date: command.day),
    );
  }

  JarvisOutcome shift(AskShift command, DateTime now) {
    final schedules = [
      for (final schedule in _ref.read(shiftSchedulesControllerProvider))
        if (schedule.isEnabled) schedule,
    ];
    List<String> workingOn(DateTime day) => [
          for (final schedule in schedules)
            if (schedule.isWorkday(day) && !schedule.isVacationWorkday(day))
              schedule.organizationName,
        ];
    var day = command.day;
    if (command.findNext && schedules.isNotEmpty) {
      // Ближайшая смена — не дальше двух месяцев: дальше графики не ведут.
      for (var i = 0; i < 62 && workingOn(day).isEmpty; i++) {
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    return JarvisOutcome(
      shiftReply(
        command,
        working: workingOn(day),
        hasSchedules: schedules.isNotEmpty,
        dayLabel: spokenWhen(day, now),
      ),
      link: schedules.isEmpty ? const OpenPlace(JarvisPlace.shifts) : null,
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
