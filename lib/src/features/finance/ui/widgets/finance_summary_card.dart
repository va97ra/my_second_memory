import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'finance_summary_value.dart';

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    required this.summary,
    required this.currencyCode,
    super.key,
  });

  final FinanceSummary summary;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final values = [
      (strings.income, summary.income.toString(), const Color(0xFF168653)),
      (strings.expenses, summary.expense.toString(), const Color(0xFFD32020)),
      (
        strings.balance,
        summary.balance.toString(),
        Theme.of(context).colorScheme.primary
      ),
    ];
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            strings.incomeAndExpenses,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(children: [
            for (final item in values)
              Expanded(
                child: FinanceSummaryValue(
                  label: item.$1,
                  value: item.$2,
                  color: item.$3,
                  currencyCode: currencyCode,
                ),
              )
          ]),
        ],
      ),
    );
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    if (screen == null) {
      return Card(
        key: const ValueKey('finance_summary_card'),
        margin: EdgeInsets.zero,
        child: content,
      );
    }
    return ScreenGlassSurface(
      key: const ValueKey('finance_summary_card'),
      colors: screen,
      opacity: screen.isDark ? 0.36 : 0.22,
      painterKey: const ValueKey('finance_summary_glass'),
      child: content,
    );
  }
}
