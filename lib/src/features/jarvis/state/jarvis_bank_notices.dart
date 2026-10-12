import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/state/bool_setting_controller.dart';
import 'jarvis_controller.dart';

/// «Записывать покупки из уведомлений банков» — выключено, пока владелец не
/// включит: нужен доступ к уведомлениям, его даёт он сам.
final jarvisBankNoticesProvider = boolSettingProvider(
  storageKey: 'jarvis_bank_notices_v1',
  initial: false,
);

/// Есть ли у приложения доступ к уведомлениям телефона. Перепроверяется,
/// когда человек возвращается в приложение: доступ дают в настройках
/// телефона, и узнать о нём раньше нельзя.
final jarvisBankAccessProvider = FutureProvider.autoDispose<bool>((ref) {
  final resumed = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(resumed.dispose);
  return ref.watch(jarvisBankWatcherProvider).accessGranted();
});

/// Джарвис читает уведомления банков, пока приложение живо: при запуске, при
/// возвращении на экран и сразу, как пришло новое.
final jarvisBankWatcherProvider = Provider<JarvisBankNotices>((ref) {
  final notices = JarvisBankNotices(
    enabled: () => ref.read(jarvisBankNoticesProvider),
    record: (entry) => ref.read(jarvisControllerProvider.notifier).act(entry),
  );
  ref
    ..listen(jarvisBankNoticesProvider, (_, on) {
      unawaited(notices.setEnabled(on));
    }, fireImmediately: true)
    ..onDispose(notices.dispose);
  notices.start();
  return notices;
});

/// Уведомления банков → расходы и доходы в финансах.
///
/// Что банковское и что в нём, решает [bankNoticeEntry]; Android только
/// откладывает уведомления с суммой (`BankNotices.kt`). Каждое разобранное
/// записывается как сказанное Джарвису «запиши расход» — тем же путём и с
/// «Отменить». Одну покупку банк присылает и пушем, и SMS: одинаковая сумма в
/// пределах [_twin] записывается один раз.
class JarvisBankNotices {
  JarvisBankNotices({
    required bool Function() enabled,
    required Future<void> Function(AddFinanceEntry entry) record,
  })  : _enabled = enabled,
        _record = record;

  static const _channel = MethodChannel('ezhednevnik_v2/bank');
  static const _twin = Duration(minutes: 10);

  final bool Function() _enabled;
  final Future<void> Function(AddFinanceEntry entry) _record;
  final _recent = <({FinanceEntryKind kind, String amount, DateTime at})>[];
  AppLifecycleListener? _lifecycle;
  Future<void>? _running;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void start() {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'noticed') unawaited(check());
    });
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(check()));
    unawaited(check());
  }

  Future<bool> accessGranted() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('accessGranted') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Экран доступа к уведомлениям в настройках телефона: включает человек.
  Future<void> openAccess() async {
    if (!_supported) return;
    await _channel.invokeMethod<void>('openAccess');
  }

  Future<void> setEnabled(bool enabled) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
    } on MissingPluginException {
      return;
    }
    if (enabled) unawaited(check());
  }

  /// Разобрать отложенное. Два вызова подряд не разбирают одно дважды.
  Future<void> check() => _running ??= _check().whenComplete(() => _running = null);

  Future<void> _check() async {
    if (!_supported || !_enabled()) return;
    final List<Object?> rows;
    try {
      rows = await _channel.invokeMethod<List<Object?>>('pending') ?? const [];
    } on MissingPluginException {
      return;
    }
    final done = <String>[];
    for (final row in rows.whereType<Map<Object?, Object?>>()) {
      done.add('${row['key']}');
      final at = DateTime.fromMillisecondsSinceEpoch(
          (row['at'] as num?)?.toInt() ?? 0);
      final entry = bankNoticeEntry(
        title: '${row['title'] ?? ''}',
        text: '${row['text'] ?? ''}',
        at: at,
        source: '${row['app'] ?? ''}',
      );
      if (entry == null || _isTwin(entry, at)) continue;
      _recent.add((kind: entry.kind, amount: entry.amount, at: at));
      await _record(entry);
    }
    if (done.isNotEmpty) {
      await _channel.invokeMethod<void>('forget', {'keys': done});
    }
  }

  bool _isTwin(AddFinanceEntry entry, DateTime at) {
    _recent.removeWhere((seen) => at.difference(seen.at).abs() > _twin * 6);
    return _recent.any((seen) =>
        seen.kind == entry.kind &&
        seen.amount == entry.amount &&
        at.difference(seen.at).abs() <= _twin);
  }

  void dispose() {
    _lifecycle?.dispose();
    if (_supported) _channel.setMethodCallHandler(null);
  }
}
