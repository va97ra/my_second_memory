/// Разбор и показ чисел, введённых человеком.
///
/// Живёт здесь, а не в фиче: этим пользуются и инструменты, и финансы. Пока
/// функции лежали в одном экране, второй фиче пришлось бы завести их копию —
/// и запятая начала бы разбираться в двух местах по-разному.
library;

/// Число из поля ввода. Запятая и точка равноправны: на русской раскладке
/// десятичный разделитель — запятая.
double? parseToolNumber(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));

/// Число для показа: без хвостовых нулей, с переходом в экспоненту там, где
/// обычная запись перестаёт читаться.
String formatToolNumber(double value, {int precision = 6}) {
  if (!value.isFinite) return '—';
  final absolute = value.abs();
  if (absolute != 0 && (absolute >= 1e9 || absolute < 1e-4)) {
    return value.toStringAsExponential(4);
  }
  final fixed = value.toStringAsFixed(precision);
  // Хвостовые нули срезаются только в дробной части: у целого числа нули
  // значащие, и `precision: 0` превращал 280 в 28.
  if (!fixed.contains('.')) return fixed;
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
