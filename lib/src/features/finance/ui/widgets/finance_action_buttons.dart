import 'package:flutter/material.dart';

class FinanceActionButtons extends StatelessWidget {
  const FinanceActionButtons({
    required this.incomeLabel,
    required this.expenseLabel,
    required this.onIncome,
    required this.onExpense,
    super.key,
  });

  final String incomeLabel;
  final String expenseLabel;
  final VoidCallback onIncome;
  final VoidCallback onExpense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('finance_add_income'),
            onPressed: onIncome,
            icon: const Icon(Icons.add_rounded),
            label: Text(incomeLabel),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            key: const ValueKey('finance_add_expense'),
            onPressed: onExpense,
            icon: const Icon(Icons.remove_rounded),
            label: Text(expenseLabel),
          ),
        ),
      ],
    );
  }
}
