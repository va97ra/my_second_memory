import 'package:flutter/material.dart';

class FinanceSummaryValue extends StatelessWidget {
  const FinanceSummaryValue({
    required this.label,
    required this.value,
    required this.color,
    required this.currencyCode,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 2,
            softWrap: true,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value $currencyCode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
