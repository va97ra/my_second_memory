import 'package:flutter/material.dart';

/// Строка-пояснение под названием графика: будильники или отпуск.
class ShiftScheduleSummaryLine extends StatelessWidget {
  const ShiftScheduleSummaryLine({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.textKey,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            key: textKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}
