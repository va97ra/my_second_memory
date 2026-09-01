/// Проверки числовых аргументов инженерных расчётов.
///
/// Три одинаковых условия нужны каждому расчёту в `tools/`, поэтому живут
/// здесь, а не копией в каждом файле.
library;

/// Число конечно и больше нуля.
void positiveValue(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'Must be finite and greater than 0');
  }
}

/// Число конечно и не отрицательно.
void nonNegativeValue(double value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'Must be finite and non-negative');
  }
}

/// Доля в диапазоне (0, 1] — cos φ, КПД.
void fractionValue(double value, String name) {
  if (!value.isFinite || value <= 0 || value > 1) {
    throw ArgumentError.value(value, name, 'Must be in the range (0, 1]');
  }
}
