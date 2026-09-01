/// Карточка учебника электрика.
///
/// Каждая карточка отвечает на три вопроса и ни на один больше: что это,
/// для чего это и что важно знать. Четвёртого поля нет нарочно — как только
/// появляется «прочее», туда стекается всё, и карточка перестаёт читаться.
///
/// Источник назван у каждой карточки. [checkedAgainstSource] отделяет
/// проверенное от написанного по общим знаниям: пока проверки нет, экран
/// говорит об этом вслух, а не молчит.
library;

enum ElectricianSection {
  /// Пошаговое обучение по уровням.
  learning,

  /// Инструмент электрика.
  tools,

  /// Компоненты электроустановки.
  components,

  /// Словарь терминов.
  glossary,

  /// Обозначения и схемы.
  schematics,

  /// Поиск причины неисправности.
  diagnostics,

  /// Электробезопасность.
  safety,

  /// Статьи справочника: коды, степени защиты, маркировка.
  reference,
}

/// Отрасль. Нужна только справочнику: его статьи служат трём
/// специальностям, а обучение и безопасность здесь — про электрику.
enum ElectricianTrade { electrical, plumbing, ventilation }

class ElectricianCard {
  const ElectricianCard({
    required this.id,
    required this.section,
    required this.titleRu,
    required this.titleEn,
    required this.whatRu,
    required this.whatEn,
    required this.purpose,
    required this.caution,
    required this.source,
    this.edition = '',
    this.checkedAgainstSource = false,
    this.aliases = const [],
    this.trade,
    this.symbol = '',
  });

  final String id;
  final ElectricianSection section;
  final String titleRu;
  final String titleEn;

  /// «Что это» — объяснение простыми словами.
  final String whatRu;
  final String whatEn;

  /// «Для чего» — практическое назначение. По-русски: как и область
  /// применения в статьях справочника, откуда карточки родом.
  final String purpose;

  /// «Что важно знать» — ограничения, типичные ошибки, опасность.
  final String caution;

  /// Документ, на который опирается карточка.
  final String source;

  /// Обозначение действующей редакции документа.
  final String edition;

  /// Проверено ли содержание карточки по названному документу.
  final bool checkedAgainstSource;

  /// Слова, по которым карточку ищут, но которых нет в заголовке.
  final List<String> aliases;

  /// Отрасль статьи справочника. `null` — карточка не про отрасль.
  final ElectricianTrade? trade;

  /// Имя условного обозначения, которое рисует приложение. Пустая строка —
  /// у карточки нет рисунка. Домен знает только имя: рисовать — дело экрана.
  final String symbol;

  String title(bool ru) => ru ? titleRu : titleEn;
  String what(bool ru) => ru ? whatRu : whatEn;

  /// Всё, по чему ищет поиск.
  String searchText(bool ru) =>
      [title(ru), what(ru), purpose, caution, ...aliases].join(' ').toLowerCase();
}
