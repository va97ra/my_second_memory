import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final financeMonthProvider = NotifierProvider<FinanceMonthController, DateTime>(
  FinanceMonthController.new,
);

/// Месяц, открытый в финансах: первое число, без времени.
class FinanceMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Листает на [offset] месяцев вперёд или назад.
  void shift(int offset) => state = DateTime(state.year, state.month + offset);
}

final financeCurrencyProvider =
    NotifierProvider<FinanceCurrencyController, String>(
  FinanceCurrencyController.new,
);

class FinanceCurrencyController extends Notifier<String> {
  static const _storageKey = 'finance_selected_currency_v1';
  late final Future<void> _loadFuture;

  @override
  String build() {
    _loadFuture = _load();
    return 'RUB';
  }

  /// Выбор, сохранённый с прошлого запуска, уже прочитан.
  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    final stored =
        (await SharedPreferences.getInstance()).getString(_storageKey);
    if (stored != null && ref.mounted) state = stored;
  }

  Future<void> select(String currencyCode) async {
    if (state == currencyCode) return;
    state = currencyCode;
    await (await SharedPreferences.getInstance())
        .setString(_storageKey, currencyCode);
  }
}
