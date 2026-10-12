import '../finance/finance_entry.dart';
import '../memory/memory_item.dart';
import '../recurrence/recurrence_series.dart';
import 'currency_phrases.dart';
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'address_phrases.dart';
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
  /// «каждый месяц 10-го в 9 часов утра». Длительность — только та, что
  /// назвал хозяин ([lengths], минуты по id записи): полчаса по умолчанию
  /// он не говорил, и повторять её в каждом ответе незачем.
  static String created(
    List<MemoryItem> items,
    DateTime now, {
    Map<String, RecurrenceFrequency> repeats = const {},
    Map<String, int> lengths = const {},
  }) {
    String one(MemoryItem item) {
      final repeat = repeats[item.id];
      final address = recordAddress(item);
      final named = lengths[item.id];
      final length = named == null ? '' : ', на ${spokenDuration(named)}';
      return '${item.title} — ${repeat == null ? _whenOf(item, now) : _repeatOf(item, repeat)}'
          '$length${address == null ? '' : ', $address'}'
          '${item.priority > 0 ? ', срочно' : ''}';
    }

    if (items.length == 1) {
      // С адресом — сразу подсказка, как туда попасть.
      final route = recordAddress(items.single) == null
          ? ''
          : ' Скажите «как доехать» — проложу маршрут.';
      return 'Записал: ${one(items.single)}.$route';
    }
    return 'Записал ${items.length} '
        '${russianPlural(items.length, 'дело', 'дела', 'дел')}: '
        '${items.map(one).join('; ')}.';
  }

  /// Вопрос о деле: «На какое время вам назначить «Врач»?», «Сколько это
  /// займёт?», «Куда нужно ехать?».
  static String question(ParsedTask task, TaskNeed need) => switch (need) {
        TaskNeed.date => 'На какой день вам назначить «${task.title}»?',
        TaskNeed.time => 'На какое время вам назначить «${task.title}»?',
        TaskNeed.duration =>
          'Сколько займёт «${task.title}» — 15 минут, полчаса, час?',
        TaskNeed.place => 'Куда нужно ехать? Если никуда — скажите «никуда».',
        TaskNeed.details =>
          'Что там сделать или взять с собой? Если нечего — «ничего».',
        TaskNeed.urgency => 'Это срочно?',
      };

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
        _ => whichRecord,
      };

  /// «Стоматолог — в пятницу в 10 часов утра.»
  /// Запись поправлена: какой она стала.
  static String edited(MemoryItem item, DateTime now) =>
      'Поправил. ${when(item, now)}';

  /// Будильник у записи не встал: нет времени, оно прошло или телефон не
  /// дал звука.
  static const noAlarm = 'Будильник не поставил: у записи нет времени впереди.';

  /// «Врач — каждый месяц 8-го в 10 часов утра.»
  static String repeating(MemoryItem item, RecurrenceFrequency frequency) =>
      '${capitalizeFirst(item.title)} — ${_repeatOf(item, frequency)}.';

  static const undatedRepeat =
      'У записки без даты повтора нет — сначала назовите день.';

  static const whichRecord = 'Какую запись? Назовите её.';

  static String notRepeating(MemoryItem item) =>
      '«${item.title}» больше не повторяется.';

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
    final source =
        entry.source == null ? '' : ' по уведомлению «${entry.source}»';
    final category = entry.category.isEmpty ? '' : ' — ${entry.category}';
    return 'Записал $what$source: $shown $name$category$day.';
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
    if (setting == JarvisSwitch.wakeWord && !enabled) {
      return 'Больше не отзываюсь на имя. Вернуть — в настройках Джарвиса '
          'или кнопкой.';
    }
    final what = switchName(setting);
    return enabled ? 'Включил $what.' : 'Выключил $what.';
  }

  /// Как переключатель называется вслух — и для нейросети.
  static String switchName(JarvisSwitch setting) => switch (setting) {
        JarvisSwitch.hints => 'подсказки',
        JarvisSwitch.holidays => 'праздники в календаре',
        JarvisSwitch.observances => 'международные дни',
        JarvisSwitch.wakeWord => 'отзыв на имя',
        JarvisSwitch.speakReminders => 'напоминания вслух',
        JarvisSwitch.detailedCards => 'подробную карточку дела',
        JarvisSwitch.morningBriefing => 'утреннюю сводку',
        JarvisSwitch.eveningBriefing => 'вечернюю сводку',
      };

  /// «Утренняя сводка — в 8 часов утра.»
  static String briefingAt(BriefingAt command) =>
      '${command.evening ? 'Вечерняя' : 'Утренняя'} сводка — '
      '${spokenAt(command.minutes)}.';

  /// Фраза без просьбы записать и без дня — дело это или разговор, не
  /// ясно. Спросить честнее, чем записать наугад.
  static const whatToDo =
      'Что вы хотите? Чтобы записать, скажите: «запиши …» или «напомни …».';

  static const undone = 'Отменил.';
  static const nothingToUndo = 'Отменять нечего: я ещё ничего не менял.';

  /// Просьба сломалась на полпути — человек должен об этом узнать.
  static const failed =
      'Не получилось — что-то пошло не так. Попробуйте ещё раз.';

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

  /// После рассказа о делах — предложить записать ещё.
  static const planMore = 'Запланировать что-нибудь ещё?';

  /// Согласились на [planMore].
  static const whatToPlan = 'Что записать?';

  /// Расход или доход записан без статьи — спросить, на что.
  static String askCategory(FinanceEntryKind kind) =>
      kind == FinanceEntryKind.expense
          ? 'На что потратили?'
          : 'Откуда этот доход?';

  static String categorized(String category) => 'Записал в «$category».';

  static String categoryKept(String category) => 'Хорошо, оставил «$category».';

  /// «Что здесь» на странице, у которой нет названия.
  static const lookNowhere = 'Здесь мне читать нечего. Спросите о делах, '
      'записках, деньгах или сменах — расскажу.';

  static const lookAccounts = 'Это ваши аккаунты. Их я не читаю: там пароли.';

  /// Архив: сколько в нём и что убрано последним.
  static String lookArchive(int count, String? latest) {
    if (count == 0) return 'Архив пуст.';
    final rows = russianPlural(count, 'запись', 'записи', 'записей');
    final last = latest == null ? '' : ' Последней убрана «$latest».';
    return 'В архиве $count $rows.$last';
  }

  /// Страница без своих записей — что на ней и что можно сказать.
  static String lookAbout(JarvisPlace place) => switch (place) {
        JarvisPlace.converter => 'Это конвертер величин. Скажите, что '
            'перевести, — например, «сколько сантиметров в 3 дюймах».',
        JarvisPlace.settings => 'Это настройки. Голосом я меняю тему, '
            'подсказки и праздники в календаре.',
        JarvisPlace.backup => 'Здесь резервные копии: всё сохранить в файл '
            'и вернуть из файла.',
        JarvisPlace.sync => 'Здесь синхронизация с облаком. Входите вы '
            'сами: пароли я не трогаю.',
        JarvisPlace.productionCalendar => 'Это производственный календарь: '
            'рабочие, выходные и праздничные дни года.',
        _ => 'Это ${_placeNames[place]}.',
      };

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

/// Ответы о дороге.
abstract final class RouteReplies {
  static String opened(String to, String app) => 'Открываю «$to» в $app.';

  static String noAddress(String title) =>
      'У записи «$title» нет адреса. Скажите, куда ехать.';

  static const where = 'Куда ехать?';

  static const noMaps = 'Карт на телефоне не нашёл.';
}
