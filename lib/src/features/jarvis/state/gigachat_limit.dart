import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'jarvis_brain_providers.dart';

/// Сколько осталось от пакета GigaChat.
///
/// [left] — остаток, как его сообщил Сбер; [most] — самый большой остаток,
/// какой он когда-либо сообщал: от него отмеряется полоска, так что она
/// честная и после смены тарифа. Остатка Сбер может не сообщать (бывает на
/// бесплатном пакете) — тогда видно хотя бы [spentThisMonth]: GigaChat
/// присылает расход в каждом ответе.
class GigaChatLimit {
  const GigaChatLimit({this.left, this.most, this.spentThisMonth = 0});

  final int? left;
  final int? most;
  final int spentThisMonth;

  /// Доля оставшегося, от 0 до 1; null — остаток неизвестен.
  double? get share {
    final left = this.left;
    final most = this.most;
    if (left == null || most == null || most <= 0) return null;
    return (left / most).clamp(0.0, 1.0);
  }
}

final StateNotifierProvider<GigaChatLimitController, GigaChatLimit>
    gigaChatLimitProvider =
    StateNotifierProvider<GigaChatLimitController, GigaChatLimit>((ref) {
  return GigaChatLimitController(
    balance: () async => ref.read(gigaChatClientProvider)?.balance(),
  );
});

class GigaChatLimitController extends StateNotifier<GigaChatLimit> {
  GigaChatLimitController({
    required Future<int?> Function() balance,
    DateTime Function()? clock,
  })  : _balance = balance,
        _clock = clock ?? DateTime.now,
        super(const GigaChatLimit()) {
    unawaited(_load());
  }

  final Future<int?> Function() _balance;
  final DateTime Function() _clock;
  DateTime? _askedAt;

  static const _leftKey = 'gigachat_left_v1';
  static const _mostKey = 'gigachat_most_v1';
  static const _spentKey = 'gigachat_spent_v1';
  static const _monthKey = 'gigachat_spent_month_v1';

  /// Остаток спрашивается не чаще раза в полминуты: это лишний запрос.
  static const _askEvery = Duration(seconds: 30);

  String get _month {
    final now = _clock();
    return '${now.year}-${now.month}';
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final sameMonth = preferences.getString(_monthKey) == _month;
    state = GigaChatLimit(
      left: preferences.getInt(_leftKey),
      most: preferences.getInt(_mostKey),
      spentThisMonth: sameMonth ? preferences.getInt(_spentKey) ?? 0 : 0,
    );
  }

  /// GigaChat ответил и сообщил расход: остаток уменьшается на него же, без
  /// запроса к Сберу.
  Future<void> spent(int tokens) async {
    final preferences = await SharedPreferences.getInstance();
    final sameMonth = preferences.getString(_monthKey) == _month;
    final total = (sameMonth ? state.spentThisMonth : 0) + tokens;
    await preferences.setString(_monthKey, _month);
    await preferences.setInt(_spentKey, total);
    if (!mounted) return;
    final left = state.left == null
        ? null
        : (state.left! - tokens).clamp(0, state.left!);
    state = GigaChatLimit(left: left, most: state.most, spentThisMonth: total);
    if (left != null) await preferences.setInt(_leftKey, left);
  }

  /// Спросить у Сбера остаток. Не ответил — остаётся прежний.
  Future<void> refresh() async {
    final now = _clock();
    final asked = _askedAt;
    if (asked != null && now.difference(asked) < _askEvery) return;
    _askedAt = now;
    final left = await _balance();
    if (left == null || !mounted) return;
    final most = state.most == null || left > state.most! ? left : state.most!;
    state = GigaChatLimit(
      left: left,
      most: most,
      spentThisMonth: state.spentThisMonth,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_leftKey, left);
    await preferences.setInt(_mostKey, most);
  }
}
