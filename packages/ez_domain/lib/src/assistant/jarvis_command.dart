import '../finance/finance_entry.dart';
import '../tools/unit_converter.dart';
import 'task_phrase.dart';

/// Что Джарвис понял из фразы — одно действие или вопрос.
///
/// Команда — это решение, а не исполнение: она ничего не сохраняет и никуда
/// не переходит. Исполняет её приложение, и одинаково — пришла ли команда от
/// правил или от нейросети. Поэтому здесь нет ни одного «как»: только «что».
sealed class JarvisCommand {
  const JarvisCommand();
}

/// Готовый ответ без действия: короткая реплика, отказ, «так не умею».
final class JarvisSay extends JarvisCommand {
  const JarvisSay(this.text);

  final String text;
}

/// Страницы, которые Джарвис открывает.
enum JarvisPlace {
  calendar,
  day,
  holidays,
  feed,
  notes,
  archive,
  accounts,
  calculator,
  finance,
  converter,
  shifts,
  productionCalendar,
  settings,
  backup,
  sync,
}

/// Открыть страницу; [date] — для дня, праздников и месяца календаря.
final class OpenPlace extends JarvisCommand {
  const OpenPlace(this.place, {this.date});

  final JarvisPlace place;
  final DateTime? date;
}

/// «Что у меня завтра», «какие дела на выходных».
final class AskAgenda extends JarvisCommand {
  const AskAgenda({required this.from, required this.to, required this.label});

  final DateTime from;
  final DateTime to;

  /// Как назвать период вслух: «завтра», «на выходных».
  final String label;

  bool get isOneDay =>
      from.year == to.year && from.month == to.month && from.day == to.day;
}

/// «Что без даты», «какие у меня записки».
final class AskUndated extends JarvisCommand {
  const AskUndated();
}

/// Записать дела в календарь. [transcript] — сказанное целиком.
final class CreateTasks extends JarvisCommand {
  const CreateTasks(
    this.tasks, {
    required this.transcript,
    this.confident = true,
    this.requested = true,
  });

  final List<ParsedTask> tasks;
  final String transcript;

  /// Человек сам просит записать: «запиши», «напомни», «надо», «не забыть».
  /// Без такой просьбы фраза — может быть, дело, а может быть, разговор
  /// («ты знаешь фильм Soulmate»), и записывать её сразу нельзя.
  final bool requested;

  /// Похоже на диктовку дела, а не на свободную речь: коротко и не вопрос.
  /// Неуверенную фразу, если подключена нейросеть, лучше отдать ей —
  /// «что мне важнее завтра?» правила записали бы делом.
  final bool confident;
}

/// Записать записку без даты.
final class CreateNote extends JarvisCommand {
  const CreateNote(this.text);

  final String text;
}

/// Что сделать с найденной записью.
enum RecordChange { complete, reopen, archive, restore, move }

/// Действие над записью, найденной по словам [query]. Пустой запрос — та
/// запись, о которой только что говорили.
final class ChangeRecord extends JarvisCommand {
  const ChangeRecord(
    this.change, {
    required this.query,
    this.date,
    this.minutes,
  });

  final RecordChange change;
  final String query;

  /// Новый день для [RecordChange.move].
  final DateTime? date;

  /// Новое время для [RecordChange.move].
  final int? minutes;
}

/// Найти записи по словам и показать их в ленте.
final class SearchRecords extends JarvisCommand {
  const SearchRecords(this.query);

  final String query;
}

/// «Когда у меня врач» — ближайшая запись по словам [query].
final class AskWhen extends JarvisCommand {
  const AskWhen(this.query);

  final String query;
}

/// Вопрос, на который правила не отвечают: «почему небо голубое», «что
/// такое ипотека». Отвечает нейросеть, если она подключена.
final class AskBrain extends JarvisCommand {
  const AskBrain(this.text);

  final String text;
}

/// Посчитать выражение калькулятором.
final class Calculate extends JarvisCommand {
  const Calculate(this.expression);

  /// Выражение языком калькулятора: «25*4», «sqrt(16)».
  final String expression;
}

/// Перевести величину: «сколько сантиметров в 3 дюймах».
final class ConvertUnits extends JarvisCommand {
  const ConvertUnits({
    required this.value,
    required this.category,
    required this.fromUnit,
    required this.toUnit,
  });

  final double value;
  final UnitCategory category;
  final String fromUnit;
  final String toUnit;
}

/// Курс или пересчёт валют по курсу ЦБ.
final class ConvertCurrency extends JarvisCommand {
  const ConvertCurrency({
    required this.amount,
    required this.from,
    required this.to,
  });

  final double amount;
  final String from;
  final String to;
}

/// Записать доход или расход в финансы.
final class AddFinanceEntry extends JarvisCommand {
  const AddFinanceEntry({
    required this.kind,
    required this.amount,
    required this.date,
    this.currency,
    this.category = '',
  });

  final FinanceEntryKind kind;

  /// Сумма десятичной строкой, как её хранит журнал: «1500», «99.90».
  final String amount;
  final DateTime date;

  /// Код валюты; не названа — валюта журнала, открытого в финансах.
  final String? currency;
  final String category;
}

/// «Сколько я потратил в этом месяце».
final class AskFinance extends JarvisCommand {
  const AskFinance({required this.kind, required this.month});

  final FinanceEntryKind kind;
  final DateTime month;
}

/// «Я завтра работаю?» — по графикам смен. «Когда смена?» — ближайшая
/// рабочая смена начиная с [day].
final class AskShift extends JarvisCommand {
  const AskShift(this.day, {this.findNext = false});

  final DateTime day;
  final bool findNext;
}

/// «Какой сегодня праздник».
final class AskHolidays extends JarvisCommand {
  const AskHolidays(this.day);

  final DateTime day;
}

/// Переключатели настроек, которыми управляет Джарвис.
enum JarvisSwitch { hints, holidays, observances }

final class SwitchSetting extends JarvisCommand {
  const SwitchSetting(this.setting, {required this.enabled});

  final JarvisSwitch setting;
  final bool enabled;
}

/// Темы, которые можно назвать голосом.
enum JarvisTheme { light, dark, cosmos }

final class ChangeTheme extends JarvisCommand {
  const ChangeTheme(this.theme);

  final JarvisTheme theme;
}

/// «Отмени», «верни как было» — отменить последнее действие Джарвиса.
final class UndoLast extends JarvisCommand {
  const UndoLast();
}
