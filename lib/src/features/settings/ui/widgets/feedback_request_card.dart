import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'settings_icon_plate.dart';

/// Просьба написать отзыв.
class FeedbackRequestCard extends StatelessWidget {
  const FeedbackRequestCard({super.key, required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return NotebookCardSurface(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsIconPlate(
              icon: Icons.rate_review_rounded,
              color: colors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRu
                        ? 'Помогите улучшить приложение'
                        : 'Help improve the app',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRu
                        ? 'Напишите, что ещё вы хотите видеть в приложении. Если оно вам понравилось, пожалуйста, поставьте оценку в RuStore.'
                        : 'Tell us what else you would like to see. If you enjoy the app, please rate it in RuStore.',
                    style: theme.textTheme.labelSmall?.copyWith(
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
