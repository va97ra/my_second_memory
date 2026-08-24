/// Сумма платежа: как она набирается в поле и как хранится.
///
/// Хранится она в копейках целым числом, а набирается как угодно — с пробелами
/// между тысячами и с запятой вместо точки.
library;

/// Сумма из набранного текста, или null, если это не сумма.
int? parseAmountMinor(String raw) {
  final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}

/// Сумма в поле ввода. Круглая сумма показывается без копеек.
String formatAmount(int? amountMinor) {
  if (amountMinor == null) return '';
  return (amountMinor / 100).toStringAsFixed(2).replaceFirst('.00', '');
}
