import 'package:flutter/material.dart';

/// Названный блок полей: «Сеть», «Нагрузка», «Линия».
///
/// Расчёт из десятка полей читается только тогда, когда поля собраны в
/// группы и у каждой группы есть имя. Без имени человек гадает, к чему
/// относится поле, и вводит длину линии в графу длины трубы.
class EngineeringSection extends StatelessWidget {
  const EngineeringSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
