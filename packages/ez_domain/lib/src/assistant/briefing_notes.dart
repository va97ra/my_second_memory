import '../finance/finance_entry.dart';
import '../memory/memory_item.dart';
import '../memory/memory_status.dart';
import '../recurrence/recurrence_dates.dart';
import 'currency_phrases.dart';
import 'history_phrases.dart' show monthsPrepositional;
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart' show isAnniversary;

/// Что Джарвис замечает сам и добавляет к сводке, как дворецкий, который
/// смотрит в календарь за хозяина: смена, неотмеченное вчера, два дела на
/// одно время, дни рождения заранее, сколько ушло вчера и — первого числа —
/// итог прошлого месяца с необычными тратами.
///
/// [day] — о каком дне сводка; [morning] — утренняя (о сегодня) или
/// вечерняя (о завтра). Деньги — только журнал финансов Ежедневника.
List<String> briefingNotes({
  required DateTime day,
  required DateTime at,
  required bool morning,
  List<String> shifts = const [],
  List<MemoryItem> dayItems = const [],
  List<MemoryItem> overdue = const [],
  List<MemoryItem> ahead = const [],
  List<FinanceEntry> finance = const [],
  String? currency,
}) {
  final notes = <String>[];
  if (shifts.isNotEmpty) {
    notes.add('${morning ? 'Сегодня' : 'Завтра'} '
        '${shifts.length == 1 ? 'смена' : 'смены'} — ${joinWithAnd(shifts)}.');
  }
  final clash = _clash(dayItems);
  if (clash != null) notes.add(clash);
  if (!morning) return notes;

  final undone = [
    for (final item in overdue)
      if (item.status == MemoryStatus.active) lowerFirst(item.title),
  ];
  if (undone.isNotEmpty) {
    final more = undone.length > 3 ? ' и ещё ${undone.length - 3}' : '';
    notes.add('Вчера не отмечено: ${joinWithAnd(undone.take(3).toList())}$more.');
  }

  for (final item in ahead) {
    if (item.status != MemoryStatus.active || !isAnniversary(item.title)) continue;
    final days = daysBetween(day, item.memoryDate);
    if (days == 1) notes.add('Завтра — ${lowerFirst(item.title)}.');
    if (days == 3) notes.add('Через 3 дня — ${lowerFirst(item.title)}.');
  }

  final code = currency;
  if (code == null) return notes;
  final today = dateOnly(at);
  final yesterday = DateTime(day.year, day.month, day.day - 1);
  // Вчерашние траты известны, только когда «вчера» уже наступило.
  if (!yesterday.isAfter(today)) {
    final spent = _sum(finance, code, yesterday, yesterday, FinanceEntryKind.expense);
    if (spent > 0) notes.add('Вчера ушло ${spokenMoney(spent, code)}.');
  }
  if (day.day == 1) notes.addAll(_monthSummary(finance, code, day));
  return notes;
}

/// «В 10 часов утра сразу два дела: врач и встреча.»
String? _clash(List<MemoryItem> items) {
  final byTime = <int, List<MemoryItem>>{};
  for (final item in items) {
    final minutes = item.timeMinutes;
    if (minutes == null || item.status != MemoryStatus.active) continue;
    byTime.putIfAbsent(minutes, () => []).add(item);
  }
  for (final MapEntry(key: minutes, value: same) in byTime.entries) {
    if (same.length < 2) continue;
    return '${capitalizeFirst(spokenAt(minutes))} сразу '
        '${same.length == 2 ? 'два дела' : '${same.length} дела'}: '
        '${joinWithAnd([for (final item in same) lowerFirst(item.title)])}.';
  }
  return null;
}

/// Итог прошлого месяца: расходы, доходы, главная статья и необычное —
/// статья, на которую ушло в полтора-два раза больше, чем в среднем за три
/// месяца до того.
List<String> _monthSummary(List<FinanceEntry> finance, String code, DateTime day) {
  final first = DateTime(day.year, day.month - 1);
  final last = DateTime(day.year, day.month, 0);
  final spent = _sum(finance, code, first, last, FinanceEntryKind.expense);
  final earned = _sum(finance, code, first, last, FinanceEntryKind.income);
  if (spent == 0 && earned == 0) return const [];
  final month = monthsPrepositional[first.month - 1];
  final notes = <String>[
    'В $month расходы — ${spokenMoney(spent, code)}, '
        'доходы — ${spokenMoney(earned, code)}.',
  ];
  final now = _byCategory(finance, code, first, last);
  if (now.isNotEmpty) {
    final top = now.entries.reduce((a, b) => a.value >= b.value ? a : b);
    notes.add('Больше всего — ${lowerFirst(top.key)}: '
        '${spokenMoney(top.value, code)}.');
  }
  final before = <Map<String, double>>[
    for (var back = 1; back <= 3; back++)
      _byCategory(
        finance,
        code,
        DateTime(first.year, first.month - back),
        DateTime(first.year, first.month - back + 1, 0),
      ),
  ];
  var unusual = 0;
  for (final MapEntry(key: category, value: sum) in now.entries) {
    final known = [for (final month in before) if (month[category] != null) month[category]!];
    if (known.length < 2) continue;
    final usual = known.reduce((a, b) => a + b) / known.length;
    if (sum < usual * 1.5 || sum - usual < 1000) continue;
    notes.add('${capitalizeFirst(category)} — '
        '${sum >= usual * 2 ? 'вдвое' : 'в полтора раза'} больше обычного.');
    if (++unusual == 2) break;
  }
  return notes;
}

double _sum(List<FinanceEntry> finance, String code, DateTime from, DateTime to,
    FinanceEntryKind kind) {
  var total = 0.0;
  for (final entry in finance) {
    final on = dateOnly(entry.occurredOn);
    if (entry.kind != kind || entry.currencyCode != code) continue;
    if (on.isBefore(from) || on.isAfter(to)) continue;
    total += double.tryParse(entry.amount) ?? 0;
  }
  return total;
}

Map<String, double> _byCategory(
    List<FinanceEntry> finance, String code, DateTime from, DateTime to) {
  final sums = <String, double>{};
  for (final entry in finance) {
    final on = dateOnly(entry.occurredOn);
    if (entry.kind != FinanceEntryKind.expense || entry.currencyCode != code) {
      continue;
    }
    if (on.isBefore(from) || on.isAfter(to)) continue;
    sums[entry.category] =
        (sums[entry.category] ?? 0) + (double.tryParse(entry.amount) ?? 0);
  }
  return sums;
}
