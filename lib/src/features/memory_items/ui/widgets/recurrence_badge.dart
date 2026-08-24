import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Отметка о том, что запись повторяется, и вход в настройку повтора.
class RecurrenceBadge extends StatelessWidget {
  const RecurrenceBadge({
    required this.frequency,
    required this.onTap,
    super.key,
  });

  final RecurrenceFrequency frequency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_repeat_rounded,
                size: 17,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                frequency.label(locale),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
