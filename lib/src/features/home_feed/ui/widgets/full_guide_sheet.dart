import 'package:flutter/material.dart';

import '../feed_guide_content.dart';
import 'guide_section_view.dart';

/// Открывает путеводитель по возможностям приложения.
Future<void> showFeedGuide(BuildContext context, {required bool ru}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FullGuideSheet(ru: ru),
  );
}

/// Лист с путеводителем: заголовок и разделы под ним.
class FullGuideSheet extends StatelessWidget {
  const FullGuideSheet({super.key, required this.ru});

  final bool ru;

  @override
  Widget build(BuildContext context) {
    final sections = feedGuideSections(ru: ru);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ru ? 'Возможности приложения' : 'App features',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: ru ? 'Закрыть' : 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: sections.length,
              itemBuilder: (context, index) =>
                  GuideSectionView(section: sections[index]),
            ),
          ),
        ],
      ),
    );
  }
}
