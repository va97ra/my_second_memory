import '../finance/finance_entry.dart';
import '../tools/unit_converter.dart';
import 'jarvis_place.dart';
import 'task_phrase.dart';

export 'jarvis_place.dart';

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

/// Открыть страницу; [date] — для дня, праздников и месяца календаря.
final class OpenPlace extends JarvisCommand {
  const OpenPlace(this.place, {this.date});

  final JarvisPlace place;
  final DateTime? date;
}

/// «Посмотри на календарь», «что в финансах», «что здесь» — посмотреть на
/// страницу и рассказать, что на ней. [place] пуст — та, что на экране.
final class LookAtPage extends JarvisCommand {
  const LookAtPage({this.place, this.date});

  final JarvisPlace? place;

  /// День для календаря и праздников: «посмотри календарь на пятницу».
  final DateTime? date;
}

/// «Что у меня завтра», «какие дела на выходных».
final class AskAgenda extends JarvisCommand {
  const AskAgenda({
    required this.from,
    required this.to,
    required this.label,
    this.important = false,
  });

  final DateTime from;
  final DateTime to;

  /// «Что самое важное завтра» — сначала главное, потом остальное.
  final bool important;

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

/// Что сделать калькулятором Ежедневника.
enum CalculatorMove {
  /// Продолжить от того, что на калькуляторе: «прибавь 10».
  chain,

  /// «Сколько получилось».
  result,
  clear,
  memorySave,
  memoryAdd,
  memorySubtract,
  memoryRecall,
  memoryClear,
  memoryRead,
  scientific,
  basic,
  degrees,
  radians,
}

/// «Прибавь 10», «сохрани в память», «очисти калькулятор» — действие
/// калькулятором, который на странице.
final class CalculatorCommand extends JarvisCommand {
  const CalculatorCommand(this.move, {this.tail = ''});

  final CalculatorMove move;

  /// Для [CalculatorMove.chain] — что сделать с тем, что на калькуляторе,
  /// языком калькулятора: «+10», «*3», «^2»; «sqrt» — корень из него.
  final String tail;
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

/// Что сделать с переводом, который на конвертере.
enum ConverterMove {
  /// «А в метрах?» — другая единица ответа.
  retarget,

  /// «А если 10?», «а 10 футов?» — другое число.
  revalue,

  /// «Поменяй местами».
  swap,
}

/// Продолжение перевода на конвертере Ежедневника.
final class ConverterCommand extends JarvisCommand {
  const ConverterCommand(this.move, {this.unit, this.category, this.value});

  final ConverterMove move;

  /// Единица: во что переводить ([ConverterMove.retarget]) или что
  /// переводят ([ConverterMove.revalue]).
  final String? unit;
  final UnitCategory? category;

  /// Новое число для [ConverterMove.revalue].
  final double? value;
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
    this.source,
  });

  final FinanceEntryKind kind;

  /// Сумма десятичной строкой, как её хранит журнал: «1500», «99.90».
  final String amount;
  final DateTime date;

  /// Код валюты; не названа — валюта журнала, открытого в финансах.
  final String? currency;
  final String category;

  /// Откуда запись, если её не диктовали: приложение банка, чьё уведомление
  /// Джарвис прочёл сам.
  final String? source;
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

/// «Какие у меня будильники», «когда будильник» — будильники Ежедневника:
/// напоминания с мелодией и будильники графиков смен.
final class AskAlarms extends JarvisCommand {
  const AskAlarms();
}

/// «Как доехать от Щёлковской до Курской» — метро Москвы. [from] пуст —
/// назвали только, куда ехать.
final class AskMetroRoute extends JarvisCommand {
  const AskMetroRoute({required this.from, required this.to});

  final String? from;
  final String to;
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

/// Команды телефону. Звонок Джарвис набирает сам, если хозяин разрешил
/// звонки, иначе открывает набор; сообщение — чат с готовым текстом,
/// «Отправить» нажимает человек.
sealed class PhoneCommand extends JarvisCommand {
  const PhoneCommand();
}

/// «Включи фонарик», «выключи фонарик».
final class PhoneTorch extends PhoneCommand {
  const PhoneTorch({required this.on});

  final bool on;
}

/// «Разбуди меня в 6:30», «поставь будильник на 7» — будильник в «Часах»
/// телефона. [minutes] — от полуночи.
final class PhoneAlarm extends PhoneCommand {
  const PhoneAlarm(this.minutes);

  final int minutes;
}

/// «Таймер на 10 минут», «засеки полчаса».
final class PhoneTimer extends PhoneCommand {
  const PhoneTimer(this.seconds);

  final int seconds;
}

/// «Позвони маме», «набери 8 916 123-45-67», «позвони Андрею и скажи, что
/// опоздаю».
final class PhoneCall extends PhoneCommand {
  const PhoneCall(this.who, {this.say});

  final String who;

  /// Что передать; сказать это в разговоре Android приложению не даёт —
  /// Джарвис напоминает хозяину.
  final String? say;
}

/// Чем отправить сообщение.
enum PhoneMessenger { sms, whatsapp, telegram }

/// «Напиши Васе в ватсап, что опоздаю».
final class PhoneMessage extends PhoneCommand {
  const PhoneMessage(this.who, this.text, {required this.app});

  final String who;
  final String text;
  final PhoneMessenger app;
}

/// «Открой камеру», «запусти телеграм» — приложение телефона. Страницы
/// Ежедневника открывает [OpenPlace], и узнаются они раньше.
final class PhoneOpenApp extends PhoneCommand {
  const PhoneOpenApp(this.name);

  final String name;
}

/// «Запомни, что мама любит белые розы» — Джарвису на память о хозяине.
final class RememberFact extends JarvisCommand {
  const RememberFact(this.fact);

  final String fact;
}

/// «Забудь, что я живу в Казани».
final class ForgetFact extends JarvisCommand {
  const ForgetFact(this.query);

  final String query;
}

/// «Что ты обо мне знаешь».
final class ListFacts extends JarvisCommand {
  const ListFacts();
}

/// «Что я делал 15 апреля», «чем я занимался в прошлом месяце» — прошлое
/// календаря, вместе со сделанным.
final class AskHistory extends JarvisCommand {
  const AskHistory({
    required this.from,
    required this.to,
    required this.label,
    this.unfinished = false,
    this.important = false,
  });

  final DateTime from;
  final DateTime to;

  /// «15 апреля», «в прошлом месяце».
  final String label;

  /// «Что я не закончил» — только неотмеченное.
  final bool unfinished;

  /// «Что важного» — сначала главное.
  final bool important;
}

/// Деньги из журнала финансов за прошлое: «когда пришла зарплата», «какие
/// расходы были вчера», «сколько ушло на такси в сентябре». Только то, что
/// записано в Ежедневнике, — в приложения банков Джарвис не ходит.
final class AskFinanceHistory extends JarvisCommand {
  const AskFinanceHistory({
    required this.from,
    required this.to,
    required this.label,
    this.kind,
    this.what = '',
    this.asksWhen = false,
  });

  final DateTime from;
  final DateTime to;
  final String label;

  /// null — и расходы, и доходы.
  final FinanceEntryKind? kind;

  /// Про что спросили: «зарплата», «такси»; пусто — про всё.
  final String what;

  /// «Когда пришла зарплата» — нужны даты, а не сумма за период.
  final bool asksWhen;
}

/// «Как доехать до врача», «проложи маршрут на Ленина 5» — маршрут в картах
/// телефона. [to] пуст — к делу, о котором только что говорили.
final class RouteTo extends JarvisCommand {
  const RouteTo(this.to);

  final String to;
}
