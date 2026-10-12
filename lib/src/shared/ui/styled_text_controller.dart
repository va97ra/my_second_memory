import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'styled_text_span.dart';

/// Что меняет кнопка панели оформления.
enum TextMarkToggle { bold, italic, underline, strike }

/// Поле с оформлением: жирный, цвет и шрифт видны прямо при наборе, а
/// хранится текст с пометками ([StyledText]). Само поле работает с чистым
/// текстом, как обычно: выделение, «Копировать», «Вставить» — системные.
class StyledTextController extends TextEditingController {
  StyledTextController() : _document = StyledText.unstyled('');

  StyledText _document;

  /// Оформление для следующего набора, если его выбрали без выделения.
  TextMark? _typing;

  /// Оформление поменялось, а текст — нет. Поле ввода сообщает только о
  /// наборе (`onChanged`), и без этого жирный или цвет не сохранялись:
  /// закрыл запись — оформление пропало.
  VoidCallback? onStyleChanged;

  StyledText get document => _document;

  /// Хранимый вид — без пробелов по краям.
  String get stored => _document.trimmed().toStored();

  /// Открыть хранимый текст записи.
  void load(String stored) {
    _document = StyledText.parse(stored);
    _typing = null;
    super.value = TextEditingValue(
      text: _document.plain,
      selection: TextSelection.collapsed(offset: _document.plain.length),
    );
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text != _document.plain) {
      _document = _document.edited(newValue.text, typing: _typing);
    } else if (newValue.selection != value.selection) {
      // Курсор переставили — выбранное без выделения оформление не тянется.
      _typing = null;
    }
    super.value = newValue;
  }

  bool get hasSelection => selection.isValid && !selection.isCollapsed;

  /// Оформление под курсором или общее у выделенного.
  TextMark get current {
    if (!selection.isValid) return TextMark.plain;
    if (!hasSelection) return _typing ?? _document.markAt(selection.start);
    final marks = _document.marksIn(selection.start, selection.end).toList();
    if (marks.isEmpty) return TextMark.plain;
    final first = marks.first;
    return TextMark(
      bold: marks.every((mark) => mark.bold),
      italic: marks.every((mark) => mark.italic),
      underline: marks.every((mark) => mark.underline),
      strike: marks.every((mark) => mark.strike),
      color: marks.every((mark) => mark.color == first.color) ? first.color : null,
      size: marks.every((mark) => mark.size == first.size) ? first.size : null,
      font: marks.every((mark) => mark.font == first.font) ? first.font : null,
    );
  }

  /// Включить или снять: если у всего выделенного уже есть — снять.
  void toggle(TextMarkToggle what) {
    final mark = current;
    final on = switch (what) {
      TextMarkToggle.bold => !mark.bold,
      TextMarkToggle.italic => !mark.italic,
      TextMarkToggle.underline => !mark.underline,
      TextMarkToggle.strike => !mark.strike,
    };
    _change((old) => switch (what) {
          TextMarkToggle.bold => old.copyWith(bold: on),
          TextMarkToggle.italic => old.copyWith(italic: on),
          TextMarkToggle.underline => old.copyWith(underline: on),
          TextMarkToggle.strike => old.copyWith(strike: on),
        });
  }

  void setColor(int? color) => _change(
      (old) => color == null ? old.copyWith(clearColor: true) : old.copyWith(color: color));

  void setSize(TextSize? size) => _change(
      (old) => size == null ? old.copyWith(clearSize: true) : old.copyWith(size: size));

  void setFont(String? font) => _change(
      (old) => font == null ? old.copyWith(clearFont: true) : old.copyWith(font: font));

  void clearFormat() => _change((_) => TextMark.plain);

  void _change(TextMark Function(TextMark) change) {
    if (!selection.isValid) return;
    if (hasSelection) {
      _document = _document.restyle(selection.start, selection.end, change);
      notifyListeners();
      onStyleChanged?.call();
    } else {
      _typing = change(current);
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Пока набирается слово, клавиатура подчёркивает его своим способом;
    // оформления в тексте нет — поле обычное.
    if (_document.isPlain || _document.plain != text) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }
    return styledTextSpan(_document, style ?? const TextStyle());
  }
}
