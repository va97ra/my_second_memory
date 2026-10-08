import '../finance/finance_entry.dart';
import '../memory/memory_item.dart';
import '../recurrence/recurrence_series.dart';
import 'currency_phrases.dart';
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart';
import '../language/russian_plural.dart';

/// Что Джарвис говорит после действия.
///
/// Подтверждение называет, что именно сделано и когда: по нему человек
/// проверяет, что его поняли правильно, и тут же может отменить. Обращение
/// («сэр») добавляет [ButlerPersona] на выходе, здесь его нет.
class JarvisReplies {
  const JarvisReplies._();

  /// «Записал: врач — завтра в 10 часов утра.» Повтор называется словами:
  /// «каждый месяц 10-го в 9 часов утра».
  static String created(
    List<MemoryItem> items,
    DateTime now, {
    Map<String, RecurrenceFrequency> repeats = const {},
  }) {
    String one(MemoryItem item) {
      final repeat = repeats[item.id];
      return '${item.title} — ${repeat == null ? _whenOf(item, now) : _repeatOf(item, repeat)}';
    }

    if (items.length == 1) return 'Записал: ${one(items.single)}.';
    return 'Записал ${items.length} '
        '${russianPlural(items.length, 'дело', 'дела', 'дел')}: '
        '${items.map(one).join('; ')}.';
  }

  /// «На какое время вам назначить «Врач»?»
  static String question(ParsedTask task) => task.need == TaskNeed.date
      ? 'На какой день вам назначить «${task.title}»?'
      : 'На какое время вам назначить «${task.title}»?';

  /// «Хорошо, «Врач» не записываю.»
  static String dropped(ParsedTask task) =>
      'Хорошо, «${task.title}» не записываю.';

  static String note(String text) => 'Записал записку: $text.';

  /// Что стало с записью после действия.
  static String changed(RecordChange change, MemoryItem item, DateTime now) {
    final title = '«${item.title}»';
    return switch (change) {
      RecordChange.complete => 'Отметил: $title выполнено.',
      RecordChange.reopen => 'Снял отметку: $title снова в работе.',
      RecordChange.archive =>
        'Убрал $title в архив — оттуда его можно вернуть.',
      RecordChange.restore => 'Вернул $title из архива.',
      RecordChange.move => 'Перенёс $title — теперь ${_whenOf(item, now)}.',
    };
  }

  static String notFound(String query) =>
      'Не нашёл записи про «$query». Скажите иначе или откройте ленту.';

  static String nothingMentioned(RecordChange change) => switch (change) {
        RecordChange.move => 'Какую запись перенести? Назовите её.',
        _ => 'Какую запись? Назовите её.',
      };

  /// «Стоматолог — в пятницу в 10 часов утра.»
  static String when(MemoryItem item, DateTime now) {
    if (item.isUndated) return '«${item.title}» — записка без даты.';
    return '${capitalizeFirst(item.title)} — ${_whenOf(item, now)}.';
  }

  static String searched(String query, int count) => count == 0
      ? 'Про «$query» записей нет.'
      : 'Нашёл про «$query»: $count '
          '${russianPlural(count, 'запись', 'записи', 'записей')}. Показываю.';

  /// «Записал расход: 500 рублей — Продукты, вчера.»
  static String financeAdded(
      AddFinanceEntry entry, String currency, DateTime now) {
    final what = entry.kind == FinanceEntryKind.expense ? 'расход' : 'доход';
    final amount = double.parse(entry.amount);
    final shown = entry.amount.replaceAll('.', ',');
    final name = currencyWords.any((word) => word.code == currency)
        ? currencyWordOf(currency).nameFor(amount)
        : currency;
    final day = entry.date.year == now.year &&
            entry.date.month == now.month &&
            entry.date.day == now.day
        ? ''
        : ', ${spokenDay(entry.date, now)}';
    return 'Записал $what: $shown $name — ${entry.category}$day.';
  }

  /// «Открываю календарь», «Открываю завтра», «Открываю ноябрь».
  static String opened(OpenPlace command, DateTime now) {
    final date = command.date;
    if (date != null && command.place == JarvisPlace.day) {
      return 'Открываю ${spokenDay(date, now)}.';
    }
    if (date != null && command.place == JarvisPlace.calendar) {
      final month = monthsNominative[date.month - 1];
      return 'Открываю $month${date.year == now.year ? '' : ' ${date.year}'}.';
    }
    return 'Открываю ${_placeNames[command.place]}.';
  }

  static String theme(JarvisTheme theme) => switch (theme) {
        JarvisTheme.light => 'Включил светлую тему.',
        JarvisTheme.dark => 'Включил тёмную тему.',
        JarvisTheme.cosmos => 'Включил тему «Космос».',
      };

  static String switched(JarvisSwitch setting, bool enabled) {
    final what = switch (setting) {
      JarvisSwitch.hints => 'подсказки',
      JarvisSwitch.holidays => 'праздники в календаре',
      JarvisSwitch.observances => 'международные дни',
    };
    return enabled ? 'Включил $what.' : 'Выключил $what.';
  }

  /// Фраза без просьбы записать и без дня — дело это или разговор, не
  /// ясно. Спросить честнее, чем записать наугад.
  static const whatToDo =
      'Что вы хотите? Чтобы записать, скажите: «запиши …» или «напомни …».';

  static const undone = 'Отменил.';
  static const nothingToUndo = 'Отменять нечего: я ещё ничего не менял.';
  static const notUnderstood =
      'Не понял, что сделать. Скажите иначе — например, «что у меня завтра».';
  static const needsBrain =
      'На такие вопросы я отвечаю с нейросетью GigaChat. Подключить её можно '
      'в настройках Джарвиса.';

  static String _repeatOf(MemoryItem item, RecurrenceFrequency frequency) {
    final date = item.memoryDate;
    final day = switch (frequency) {
      RecurrenceFrequency.monthly => 'каждый месяц ${date.day}-го',
      RecurrenceFrequency.yearly =>
        'каждый год ${date.day} ${monthsGenitive[date.month - 1]}',
    };
    final minutes = item.timeMinutes;
    return minutes == null ? day : '$day ${spokenAt(minutes)}';
  }

  static String _whenOf(MemoryItem item, DateTime now) {
    if (item.isUndated) return 'без даты';
    return spokenMoment(item.memoryDate, item.timeMinutes, now);
  }

  static const _placeNames = {
    JarvisPlace.calendar: 'календарь',
    JarvisPlace.day: 'день',
    JarvisPlace.holidays: 'праздники',
    JarvisPlace.feed: 'ленту',
    JarvisPlace.notes: 'записки',
    JarvisPlace.archive: 'архив',
    JarvisPlace.accounts: 'аккаунты',
    JarvisPlace.calculator: 'калькулятор',
    JarvisPlace.finance: 'финансы',
    JarvisPlace.converter: 'конвертер',
    JarvisPlace.shifts: 'графики смен',
    JarvisPlace.productionCalendar: 'производственный календарь',
    JarvisPlace.settings: 'настройки',
    JarvisPlace.backup: 'резервные копии',
    JarvisPlace.sync: 'синхронизацию',
  };
}
