import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinanceDateButton extends StatelessWidget {
  const FinanceDateButton({
    required this.date,
    required this.onPressed,
    super.key,
  });

  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.event_rounded),
      label: Text(
        '${strings.operationDate}: ${DateFormat.yMMMd(locale).format(date)}',
      ),
    );
  }
}
