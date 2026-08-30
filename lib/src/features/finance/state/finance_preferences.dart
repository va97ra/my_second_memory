import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final financeMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final financeCurrencyProvider =
    StateNotifierProvider<FinanceCurrencyController, String>((ref) {
  return FinanceCurrencyController()..load();
});

class FinanceCurrencyController extends StateNotifier<String> {
  FinanceCurrencyController() : super('RUB');

  static const _storageKey = 'finance_selected_currency_v1';

  Future<void> load() async {
    state =
        (await SharedPreferences.getInstance()).getString(_storageKey) ?? state;
  }

  Future<void> select(String currencyCode) async {
    if (state == currencyCode) return;
    state = currencyCode;
    await (await SharedPreferences.getInstance())
        .setString(_storageKey, currencyCode);
  }
}
