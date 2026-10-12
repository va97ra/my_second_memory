import 'package:meta/meta.dart';

/// Размер куска текста относительно обычного.
enum TextSize {
  small(0.85),
  large(1.25),
  huge(1.6);

  const TextSize(this.scale);

  final double scale;
}

/// Оформление куска текста записи: жирный, курсив, подчёркнутый,
/// зачёркнутый, цвет, размер и шрифт.
@immutable
class TextMark {
  const TextMark({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.color,
    this.size,
    this.font,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  /// Цвет 0xRRGGBB; null — цвет темы.
  final int? color;
  final TextSize? size;

  /// Шрифт по имени из списка шрифтов приложения; null — шрифт записи.
  final String? font;

  static const plain = TextMark();

  bool get isPlain => this == plain;

  TextMark copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    int? color,
    bool clearColor = false,
    TextSize? size,
    bool clearSize = false,
    String? font,
    bool clearFont = false,
  }) =>
      TextMark(
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        strike: strike ?? this.strike,
        color: clearColor ? null : color ?? this.color,
        size: clearSize ? null : size ?? this.size,
        font: clearFont ? null : font ?? this.font,
      );

  @override
  bool operator ==(Object other) =>
      other is TextMark &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strike == strike &&
      other.color == color &&
      other.size == size &&
      other.font == font;

  @override
  int get hashCode =>
      Object.hash(bold, italic, underline, strike, color, size, font);
}

/// Кусок текста с одним оформлением: [start, end).
@immutable
class StyledRun {
  const StyledRun(this.start, this.end, this.mark);

  final int start;
  final int end;
  final TextMark mark;
}

/// Текст записи с оформлением.
///
/// Хранится в самом тексте записи, короткими пометками, — без новой колонки
/// в базе: так оформление без переделок ездит через синхронизацию и
/// резервные копии, а версия приложения без оформления не теряет ни слова
/// (покажет пометки как есть). Неоформленный текст хранится как был.
///
/// Вид хранения: невидимый знак [marker] в начале, дальше текст, а
/// оформленные куски — `<f a="bi" c="E53935" z="large" n="lora">…</f>`;
/// `&`, `<`, `>` внутри экранируются. Чистый текст — для поиска,
/// уведомлений, Джарвиса и названия записи — [plainOf].
@immutable
class StyledText {
  StyledText(this.plain, List<TextMark> marks)
      : assert(marks.length == plain.length),
        _marks = List.unmodifiable(marks);

  StyledText.unstyled(this.plain)
      : _marks = List.filled(plain.length, TextMark.plain);

  /// Невидимый разделитель (U+2063): с него начинается оформленный текст.
  static const marker = '⁣';

  final String plain;

  /// Оформление каждого знака.
  final List<TextMark> _marks;

  bool get isPlain => _marks.every((mark) => mark.isPlain);

  /// Чистый текст хранимого — без разбора, если оформления нет.
  static String plainOf(String stored) =>
      stored.startsWith(marker) ? StyledText.parse(stored).plain : stored;

  factory StyledText.parse(String stored) {
    if (!stored.startsWith(marker)) return StyledText.unstyled(stored);
    final text = StringBuffer();
    final marks = <TextMark>[];
    var from = marker.length;
    void plainPart(String part) {
      final value = _unescape(part);
      text.write(value);
      marks.addAll(List.filled(value.length, TextMark.plain));
    }

    for (final match in _run.allMatches(stored, from)) {
      plainPart(stored.substring(from, match.start));
      final value = _unescape(match.group(2)!);
      final mark = _markOf(match.group(1)!);
      text.write(value);
      marks.addAll(List.filled(value.length, mark));
      from = match.end;
    }
    plainPart(stored.substring(from));
    return StyledText(text.toString(), marks);
  }

  /// Дописать чистый текст в конец, сохранив оформление написанного.
  StyledText appended(String text) => StyledText('$plain$text', [
        ..._marks,
        ...List.filled(text.length, TextMark.plain),
      ]);

  /// Как хранить: без оформления — сам текст.
  String toStored() {
    if (isPlain) return plain;
    final out = StringBuffer(marker);
    for (final run in runs(includePlain: true)) {
      final part = _escape(plain.substring(run.start, run.end));
      if (run.mark.isPlain) {
        out.write(part);
      } else {
        out.write('<f${_attributes(run.mark)}>$part</f>');
      }
    }
    return out.toString();
  }

  /// Куски с одинаковым оформлением подряд.
  List<StyledRun> runs({bool includePlain = false}) {
    final result = <StyledRun>[];
    var start = 0;
    for (var i = 1; i <= plain.length; i++) {
      if (i < plain.length && _marks[i] == _marks[start]) continue;
      if (includePlain || !_marks[start].isPlain) {
        result.add(StyledRun(start, i, _marks[start]));
      }
      start = i;
    }
    return result;
  }

  /// Оформление, с которым продолжится набор в позиции [offset]: как у
  /// знака перед ней.
  TextMark markAt(int offset) =>
      offset <= 0 || _marks.isEmpty ? TextMark.plain : _marks[offset - 1];

  /// Оформление каждого знака [start, end) — для решения «включить или
  /// снять».
  Iterable<TextMark> marksIn(int start, int end) =>
      _marks.sublist(start.clamp(0, plain.length), end.clamp(0, plain.length));

  /// Кусок [start, end) с его оформлением.
  StyledText slice(int start, int end) =>
      StyledText(plain.substring(start, end), _marks.sublist(start, end));

  /// Пробелы и переводы строки схлопнуты в один пробел, по краям их нет —
  /// одной строкой, как название записи. Оформление слов остаётся.
  StyledText collapsed() {
    final text = StringBuffer();
    final marks = <TextMark>[];
    var gap = false;
    for (var i = 0; i < plain.length; i++) {
      final char = plain[i];
      if (char.trim().isEmpty) {
        gap = true;
        continue;
      }
      if (gap && text.isNotEmpty) {
        // Пробел оформлен, только если оформление по обе стороны одно:
        // подчёркнутое не тянется на соседнее слово.
        text.write(' ');
        marks.add(marks.last == _marks[i] ? _marks[i] : TextMark.plain);
      }
      gap = false;
      text.write(char);
      marks.add(_marks[i]);
    }
    return StyledText(text.toString(), marks);
  }

  /// Без пробелов и переводов строки по краям — оформление слов остаётся.
  StyledText trimmed() {
    var start = 0;
    var end = plain.length;
    while (start < end && plain[start].trim().isEmpty) {
      start++;
    }
    while (end > start && plain[end - 1].trim().isEmpty) {
      end--;
    }
    if (start == 0 && end == plain.length) return this;
    return StyledText(plain.substring(start, end), _marks.sublist(start, end));
  }

  /// Изменить оформление куска [start, end).
  StyledText restyle(int start, int end, TextMark Function(TextMark) change) {
    final marks = [..._marks];
    for (var i = start.clamp(0, plain.length);
        i < end.clamp(0, plain.length);
        i++) {
      marks[i] = change(marks[i]);
    }
    return StyledText(plain, marks);
  }

  /// Текст исправили: оформление остаётся на своих словах, вставленное
  /// берёт [typing] или оформление знака перед ним.
  StyledText edited(String text, {TextMark? typing}) {
    if (text == plain) return this;
    var prefix = 0;
    final shortest = text.length < plain.length ? text.length : plain.length;
    while (prefix < shortest && text.codeUnitAt(prefix) == plain.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest - prefix &&
        text.codeUnitAt(text.length - 1 - suffix) ==
            plain.codeUnitAt(plain.length - 1 - suffix)) {
      suffix++;
    }
    final inserted = text.length - prefix - suffix;
    final mark = typing ?? markAt(prefix);
    return StyledText(text, [
      ..._marks.sublist(0, prefix),
      ...List.filled(inserted, mark),
      ..._marks.sublist(plain.length - suffix),
    ]);
  }

  static final _run = RegExp(r'<f([^>]*)>(.*?)</f>', dotAll: true);
  static final _attribute = RegExp(r'(\w)="([^"]*)"');

  static TextMark _markOf(String attributes) {
    var mark = TextMark.plain;
    for (final match in _attribute.allMatches(attributes)) {
      final value = match.group(2)!;
      mark = switch (match.group(1)) {
        'a' => mark.copyWith(
            bold: value.contains('b'),
            italic: value.contains('i'),
            underline: value.contains('u'),
            strike: value.contains('s'),
          ),
        'c' => mark.copyWith(color: int.tryParse(value, radix: 16)),
        'z' => mark.copyWith(
            size: TextSize.values.where((size) => size.name == value).firstOrNull),
        'n' => mark.copyWith(font: value),
        _ => mark,
      };
    }
    return mark;
  }

  static String _attributes(TextMark mark) {
    final flags = [
      if (mark.bold) 'b',
      if (mark.italic) 'i',
      if (mark.underline) 'u',
      if (mark.strike) 's',
    ].join();
    return [
      if (flags.isNotEmpty) ' a="$flags"',
      if (mark.color case final color?)
        ' c="${color.toRadixString(16).padLeft(6, '0').toUpperCase()}"',
      if (mark.size case final size?) ' z="${size.name}"',
      if (mark.font case final font?) ' n="$font"',
    ].join();
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _unescape(String text) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
