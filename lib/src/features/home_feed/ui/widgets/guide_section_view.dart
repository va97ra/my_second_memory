import 'package:flutter/material.dart';

import '../feed_guide_content.dart';

/// Один раздел путеводителя: заголовок и его строки.
class GuideSectionView extends StatelessWidget {
  const GuideSectionView({super.key, required this.section});

  final FeedGuideSection section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          for (final item in section.items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 28,
              leading: Icon(item.icon, size: 20, color: colors.primary),
              title: Text(
                item.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
