import 'package:flutter/material.dart';

/// Подсказка о том, где включается повтор записи.
class RecurrenceHint extends StatelessWidget {
  const RecurrenceHint({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.event_repeat_rounded, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ru
                      ? 'Чтобы повторять запись, нажмите ↻ в правом верхнем углу.'
                      : 'To repeat a record, tap ↻ in the top-right corner.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
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
