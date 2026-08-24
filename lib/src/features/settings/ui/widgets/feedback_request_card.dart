import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Просьба написать отзыв. Показывается вместе с подсказками: тот, кто их
/// выключил, приложение уже освоил.
class FeedbackRequestCard extends StatelessWidget {
  const FeedbackRequestCard({super.key, required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: notebookSurfaceShadow(context, NotebookSurfaceDepth.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.rate_review_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRu
                        ? 'Помогите улучшить приложение'
                        : 'Help improve the app',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRu
                        ? 'Напишите, что ещё вы хотите видеть в приложении. Если оно вам понравилось, пожалуйста, поставьте оценку в RuStore.'
                        : 'Tell us what else you would like to see. If you enjoy the app, please rate it in RuStore.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
