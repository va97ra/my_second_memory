import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme_controller.dart';
import '../../../shared/state/app_hints_provider.dart';
import '../../calendar/calendar.dart';
import '../../finance/finance.dart';
import 'jarvis_outcome.dart';

/// Джарвис меняет то, что человек может переключить и сам: тему,
/// переключатели настроек, запись в журнале финансов. Каждое действие
/// отменяется возвратом прежнего значения.
class JarvisSettingsActions {
  const JarvisSettingsActions(this._ref);

  final Ref _ref;

  Future<JarvisOutcome> theme(ChangeTheme command) async {
    final controller = _ref.read(appThemeControllerProvider.notifier);
    final previous = _ref.read(appThemeControllerProvider);
    await controller.setStyle(appThemeStyleOf(command.theme));
    return JarvisOutcome(
      JarvisReplies.theme(command.theme),
      undo: () => controller.setStyle(previous),
    );
  }

  Future<JarvisOutcome> toggle(SwitchSetting command) async {
    final provider = switch (command.setting) {
      JarvisSwitch.hints => appHintsProvider,
      JarvisSwitch.holidays => appHolidaysProvider,
      JarvisSwitch.observances => appObservancesProvider,
    };
    final controller = _ref.read(provider.notifier);
    final previous = _ref.read(provider);
    await controller.setEnabled(command.enabled);
    return JarvisOutcome(
      JarvisReplies.switched(command.setting, command.enabled),
      undo: () => controller.setEnabled(previous),
    );
  }

  /// Доход или расход в журнал. Валюта — названная, а если не названа —
  /// та, чей журнал открыт в финансах. Категория пишется так, как она уже
  /// встречается в журнале: «на продукты» попадает в «Продукты», а не
  /// заводит вторую такую же.
  Future<JarvisOutcome> addFinance(
      AddFinanceEntry command, DateTime now) async {
    final controller = _ref.read(financeControllerProvider.notifier);
    final String journal = _ref.read(financeCurrencyProvider);
    final currency = command.currency ?? journal;
    final named = command.category.isNotEmpty;
    final entry = FinanceEntry(
      id: 'finance_${now.microsecondsSinceEpoch}',
      kind: command.kind,
      amount: command.amount,
      currencyCode: currency,
      category: named
          ? _knownCategory(command.category)
          : defaultFinanceCategory(command.kind),
      occurredOn: command.date,
      createdAt: now,
      updatedAt: now,
    );
    await controller.add(entry);
    // Продиктовано — Джарвис идёт в «Финансы» и записывает там; не сказали,
    // на что, — записывает в «Прочее» и спрашивает (просьба владельца
    // 12 октября 2026). Покупка из уведомления банка — без перехода и без
    // вопросов: её Джарвис записывает сам, за спиной.
    final dictated = command.source == null;
    final asks = dictated && !named;
    final added = JarvisReplies.financeAdded(
      AddFinanceEntry(
        kind: entry.kind,
        amount: entry.amount,
        date: entry.occurredOn,
        currency: currency,
        category: named ? entry.category : '',
        source: command.source,
      ),
      currency,
      now,
    );
    const place = OpenPlace(JarvisPlace.finance);
    return JarvisOutcome(
      asks ? '$added ${JarvisReplies.askCategory(entry.kind)}' : added,
      open: dictated ? place : null,
      link: dictated ? null : place,
      undo: () => controller.delete(entry.id),
      followUp: asks ? (said, now) => _categorize(entry, said, now) : null,
    );
  }

  /// Ответ на «На что потратили?»: статья этой же записи.
  Future<JarvisOutcome> _categorize(
      FinanceEntry entry, String said, DateTime now) async {
    final answer = financeCategoryAnswer(said);
    if (answer.isEmpty) {
      return JarvisOutcome(JarvisReplies.categoryKept(entry.category));
    }
    final controller = _ref.read(financeControllerProvider.notifier);
    final named = entry.copyWith(
      category: _knownCategory(answer),
      updatedAt: now,
    );
    await controller.update(named);
    return JarvisOutcome(
      JarvisReplies.categorized(named.category),
      undo: () => controller.update(entry),
    );
  }

  String _knownCategory(String said) {
    final stems = searchStems(said);
    if (stems.isEmpty) return said;
    for (final entry in _ref.read(financeControllerProvider)) {
      final known = searchStems(entry.category);
      if (known.length == stems.length &&
          [for (var i = 0; i < stems.length; i++) known[i] == stems[i]]
              .every((same) => same)) {
        return entry.category;
      }
    }
    return said;
  }
}
