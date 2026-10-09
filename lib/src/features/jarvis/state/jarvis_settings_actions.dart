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
  Future<JarvisOutcome> addFinance(AddFinanceEntry command, DateTime now) async {
    final controller = _ref.read(financeControllerProvider.notifier);
    final String journal = _ref.read(financeCurrencyProvider);
    final currency = command.currency ?? journal;
    final entry = FinanceEntry(
      id: 'finance_${now.microsecondsSinceEpoch}',
      kind: command.kind,
      amount: command.amount,
      currencyCode: currency,
      category: _knownCategory(command.category),
      occurredOn: command.date,
      createdAt: now,
      updatedAt: now,
    );
    await controller.add(entry);
    return JarvisOutcome(
      JarvisReplies.financeAdded(
        AddFinanceEntry(
          kind: entry.kind,
          amount: entry.amount,
          date: entry.occurredOn,
          currency: currency,
          category: entry.category,
          source: command.source,
        ),
        currency,
        now,
      ),
      link: const OpenPlace(JarvisPlace.finance),
      undo: () => controller.delete(entry.id),
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
