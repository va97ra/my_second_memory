import 'package:ez_design/ez_design.dart';
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
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    return Row(
      children: [
        Expanded(
          child: screen == null
              ? FilledButton.icon(
                  key: const ValueKey('finance_add_income'),
                  onPressed: onIncome,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(incomeLabel),
                )
              : _glassButton(
                  key: const ValueKey('finance_add_income'),
                  screen: screen,
                  label: incomeLabel,
                  icon: Icons.add_rounded,
                  onPressed: onIncome,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: screen == null
              ? FilledButton.tonalIcon(
                  key: const ValueKey('finance_add_expense'),
                  onPressed: onExpense,
                  icon: const Icon(Icons.remove_rounded),
                  label: Text(expenseLabel),
                )
              : _glassButton(
                  key: const ValueKey('finance_add_expense'),
                  screen: screen,
                  label: expenseLabel,
                  icon: Icons.remove_rounded,
                  onPressed: onExpense,
                ),
        ),
      ],
    );
  }

  Widget _glassButton({
    required Key key,
    required ScreenThemeColors screen,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ScreenGlassButton(
        key: key,
        opacity: 0.58,
        tint: screen.accent,
        semanticLabel: label,
        onPressed: onPressed,
        painterKey: const ValueKey('finance_action_glass'),
        lampKey: ValueKey('finance_action_lamp_$label'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(icon, color: screen.onAccent),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: screen.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
