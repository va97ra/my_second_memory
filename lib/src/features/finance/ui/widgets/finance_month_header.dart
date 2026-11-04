import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/ui/chrome/main_page_header.dart';
import '../../state/finance_currencies.dart';

/// Шапка финансов: стрелки месяца по краям, посередине месяц и валюта, рядом с
/// правой стрелкой конвертер.
class FinanceMonthHeader extends StatelessWidget {
  const FinanceMonthHeader({
    required this.currency,
    required this.month,
    required this.onCurrency,
    required this.onMonthDelta,
    required this.onConverter,
    super.key,
  });

  final String currency;
  final DateTime month;
  final ValueChanged<String> onCurrency;
  final ValueChanged<int> onMonthDelta;
  final VoidCallback onConverter;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    return MainPageHeader(
      cardKey: const ValueKey('finance_header_card'),
      hint: strings.financePageHint,
      leading: [
        _arrow(
          const ValueKey('finance_previous_month'),
          Icons.chevron_left_rounded,
          () => onMonthDelta(-1),
        ),
      ],
      trailing: [
        IconButton(
          key: const ValueKey('finance_converter'),
          tooltip: strings.currencyConverter,
          onPressed: onConverter,
          icon: const Icon(Icons.currency_exchange_rounded, size: 20),
          style: notebookIconButtonStyle(),
        ),
        _arrow(
          const ValueKey('finance_next_month'),
          Icons.chevron_right_rounded,
          () => onMonthDelta(1),
        ),
      ],
      center: NotebookHeaderTitle(
        title: Text(DateFormat.yMMM(locale).format(month), maxLines: 1),
        details: Center(
          child: DropdownButton<String>(
            key: const ValueKey('finance_currency'),
            value: currency,
            isDense: true,
            iconSize: 16,
            underline: const SizedBox.shrink(),
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
            items: [
              for (final code in financeCurrencyCodes)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (value) {
              if (value != null) onCurrency(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _arrow(Key key, IconData icon, VoidCallback onPressed) => IconButton(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        style: notebookIconButtonStyle(),
      );
}
