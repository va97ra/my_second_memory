import '../feed/feed_rules.dart';
import '../memory/memory_item.dart';
import '../memory/memory_status.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import '../language/russian_plural.dart';

/// Как Джарвис рассказывает о делах — как дворецкий в кино: «Сэр, на
/// сегодня 3 дела. Ближайшее — в 2 часа дня: встреча с Иваном. Затем в 6
/// часов вечера — позвонить маме. Также без точного времени: купить хлеб.»
///
/// Выполненные и архивные записи не рассказываются: их уже не нужно делать.
class AgendaSpeech {
  const AgendaSpeech._();

  /// «одно дело», «3 дела», «5 дел».
  static String count(int count) => count == 1
      ? 'одно дело'
      : '$count ${russianPlural(count, 'дело', 'дела', 'дел')}';

  /// Обращение в начале фразы: «Сэр, ».
  static String hello(String address) {
    final trimmed = address.trim();
    return trimmed.isEmpty ? '' : '${capitalizeFirst(trimmed)}, ';
  }

  /// Дела одного дня. [label] — «сегодня», «завтра», «в пятницу», «на 15
  /// октября».
  static String day(
    List<MemoryItem> items, {
    required DateTime day,
    required DateTime now,
    required String label,
    String address = '',
  }) {
    final open = _open(items);
    final on =
        label.startsWith('в ') || label.startsWith('на ') ? label : 'на $label';
    if (open.isEmpty) return capitalizeFirst('${hello(address)}$on дел нет.');
    final today = isSameDay(day, now);
    if (open.length == 1) {
      final item = open.single;
      final minutes = item.timeMinutes;
      final when = minutes == null ? '' : '${spokenAt(minutes)} — ';
      final passed = today && minutes != null && minutes < _minutesOf(now)
          ? ' Время уже прошло, но дело не отмечено.'
          : '';
      return '${capitalizeFirst('${hello(address)}$on одно дело: ')}'
          '$when${lowerFirst(item.title)}.$passed';
    }
    return '${capitalizeFirst('${hello(address)}$on ${count(open.length)}.')} '
        '${_inOrder(open, now: today ? now : null)}';
  }

  /// Дела нескольких дней списком: «На выходных 3 дела: в субботу в 10
  /// часов утра — дача; …».
  static String range(
    List<MemoryItem> items, {
    required DateTime now,
    required String label,
    String address = '',
  }) {
    final open = _open(items)
      ..sort((left, right) {
        final byDay = left.memoryDate.compareTo(right.memoryDate);
        if (byDay != 0) return byDay;
        return (left.timeMinutes ?? -1).compareTo(right.timeMinutes ?? -1);
      });
    if (open.isEmpty) {
      return capitalizeFirst('${hello(address)}$label дел нет.');
    }
    return capitalizeFirst('${hello(address)}$label ${count(open.length)}: '
        '${_list(open, daysFrom: now)}.');
  }

  /// Напоминание вслух в его момент: «Сэр, напоминаю: в 2 часа дня —
  /// встреча с Иваном.» Заранее — сколько осталось: «Сэр, через 30 минут, в
  /// 2 часа дня — встреча.» Дело другого дня — с днём: «Сэр, напоминаю:
  /// завтра в 10 часов утра — врач.»
  static String reminder(
    MemoryItem item, {
    required DateTime at,
    String address = '',
  }) {
    final title = lowerFirst(item.title.trim());
    final remind = '${hello(address)}напоминаю: ';
    final minutes = item.timeMinutes;
    if (item.isUndated) return capitalizeFirst('$remind$title.');
    final day = item.memoryDate;
    final sameDay = isSameDay(day, at);
    if (minutes == null) {
      final when = sameDay ? 'сегодня' : spokenWhen(day, at);
      return capitalizeFirst('$remind$when — $title.');
    }
    final start = DateTime(day.year, day.month, day.day, minutes ~/ 60,
        minutes % 60);
    final ahead = start.difference(at).inMinutes;
    if (sameDay && ahead > 0) {
      return capitalizeFirst('${hello(address)}через ${spokenDuration(ahead)}, '
          '${spokenAt(minutes)} — $title.');
    }
    final when = sameDay ? spokenAt(minutes) : spokenMoment(day, minutes, at);
    return capitalizeFirst('$remind$when — $title.');
  }

  /// Голос за будильником смены: «Доброе утро, сэр! Сегодня рабочая смена
  /// — Завод.» Утро после суточной: «Доброе утро, сэр! Суточная смена
  /// позади — Завод.»
  static String shiftAlarm(
    String organization, {
    required bool afterNightShift,
    String address = '',
  }) {
    final name = address.trim();
    final hi = name.isEmpty ? 'Доброе утро!' : 'Доброе утро, $name!';
    final what = organization.trim();
    final shift =
        afterNightShift ? 'Суточная смена позади' : 'Сегодня рабочая смена';
    return what.isEmpty ? '$hi $shift.' : '$hi $shift — $what.';
  }

  /// Сводка дня — утром на сегодня, вечером на завтра: «Доброе утро, сэр!
  /// На сегодня 2 дела» и по порядку, что за дела. null — дел нет, и
  /// беспокоить незачем.
  static ({String title, String body})? briefing(
    List<MemoryItem> items, {
    required DateTime day,
    required DateTime at,
    String address = '',
  }) {
    final open = _open(items);
    if (open.isEmpty) return null;
    final today = isSameDay(day, at);
    final name = address.trim();
    final what = 'на ${spokenDay(day, at)} ${count(open.length)}';
    return (
      title: today && at.hour < 12
          ? '${name.isEmpty ? 'Доброе утро' : 'Доброе утро, $name'}! '
              '${capitalizeFirst(what)}'
          : capitalizeFirst('${hello(address)}$what'),
      body: _inOrder(open, now: today ? at : null),
    );
  }

  /// Записки без даты.
  static String undated(List<MemoryItem> notes, {String address = ''}) {
    final open = _open(notes);
    if (open.isEmpty) {
      return capitalizeFirst('${hello(address)}записок без даты нет.');
    }
    final noun = russianPlural(open.length, 'записка', 'записки', 'записок');
    return capitalizeFirst('${hello(address)}без даты ${open.length} $noun: '
        '${_list(open)}.');
  }

  static List<MemoryItem> _open(List<MemoryItem> items) => [
        for (final item in items)
          if (item.status == MemoryStatus.active) item,
      ];

  static int _minutesOf(DateTime moment) => moment.hour * 60 + moment.minute;

  /// «Первое — в 9 часов утра: … Затем в 2 часа дня — … Также без точного
  /// времени: …». Для сегодняшнего дня ([now] задан) прошедшее — отдельно, а
  /// первым идёт ближайшее.
  static String _inOrder(List<MemoryItem> items, {DateTime? now}) {
    final timed = [
      for (final item in items)
        if (item.timeMinutes != null) item,
    ]..sort((left, right) => left.timeMinutes!.compareTo(right.timeMinutes!));
    final untimed = [
      for (final item in items)
        if (item.timeMinutes == null) item,
    ];
    final nowMinutes = now == null ? null : _minutesOf(now);
    final past = nowMinutes == null
        ? const <MemoryItem>[]
        : [
            for (final item in timed)
              if (item.timeMinutes! < nowMinutes) item,
          ];
    final ahead = [
      for (final item in timed)
        if (!past.contains(item)) item,
    ];
    final sentences = <String>[];
    for (var i = 0; i < ahead.length; i++) {
      final at = spokenAt(ahead[i].timeMinutes!);
      final title = lowerFirst(ahead[i].title);
      sentences.add(switch (i) {
        0 when ahead.length == 1 => '${capitalizeFirst(at)} — $title.',
        0 => '${now == null ? 'Первое' : 'Ближайшее'} — $at: $title.',
        1 => 'Затем $at — $title.',
        _ => 'Далее $at — $title.',
      });
    }
    if (untimed.isNotEmpty) {
      final what =
          joinWithAnd([for (final item in untimed) lowerFirst(item.title)]);
      sentences.add(ahead.isEmpty
          ? 'Без точного времени: $what.'
          : 'Также без точного времени: $what.');
    }
    if (past.isNotEmpty) {
      final what = joinWithAnd([
        for (final item in past)
          '${spokenAt(item.timeMinutes!)} — ${lowerFirst(item.title)}',
      ]);
      sentences.add('Уже прошло, но не отмечено: $what.');
    }
    return sentences.join(' ');
  }

  /// Записи через точку с запятой; с [daysFrom] — с днём каждой записи,
  /// названным относительно этого момента.
  static String _list(List<MemoryItem> items, {DateTime? daysFrom}) {
    const shown = 10;
    final parts = [
      for (final item in items.take(shown)) _entry(item, daysFrom),
    ];
    final more = items.length > shown ? '; и ещё ${items.length - shown}' : '';
    return parts.join('; ') + more;
  }

  static String _entry(MemoryItem item, DateTime? daysFrom) {
    final minutes = item.timeMinutes;
    final when = [
      if (daysFrom != null) spokenDay(item.memoryDate, daysFrom),
      if (minutes != null) spokenAt(minutes),
    ].join(' ');
    final title = lowerFirst(item.title);
    return when.isEmpty ? title : '$when — $title';
  }
}
