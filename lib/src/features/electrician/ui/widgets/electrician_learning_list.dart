import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'learning_topic_sheet.dart';

/// Список тем обучения с полосой прогресса.
///
/// Пройденная тема помечена и остаётся доступной: к объяснению возвращаются
/// чаще, чем к тесту.
class ElectricianLearningList extends ConsumerWidget {
  const ElectricianLearningList({required this.query, super.key});

  /// Строка поиска: темы отбираются по ней так же, как карточки.
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    final snapshot = ref.watch(toolDataControllerProvider).valueOrNull ??
        const ToolDataSnapshot();
    final passed = {
      for (final record in snapshot.learning) record.topicId,
    };
    final needle = query.trim().toLowerCase();
    final topics = [
      for (final topic in learningTopics)
        if (needle.isEmpty ||
            '${topic.title(ru)} ${topic.explanation(ru)}'
                .toLowerCase()
                .contains(needle))
          topic,
    ];
    final share = learningProgress(passed);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.learned,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text('${(share * 100).round()} %'),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: share, minHeight: 8),
              ),
            ],
          ),
        ),
        Expanded(
          child: topics.isEmpty
              ? Center(child: Text(strings.nothingFound))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final level in learningLevels)
                      if (topics.any((topic) => topic.level == level)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                          child: Text(
                            strings.levelTitle(level).toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(letterSpacing: 1.2),
                          ),
                        ),
                        for (final topic in topics)
                          if (topic.level == level)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TopicTile(
                                topic: topic,
                                done: passed.contains(topic.id),
                              ),
                            ),
                      ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.done});

  final LearningTopic topic;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ru = AppStrings.of(context).isRu;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: done ? scheme.primary : scheme.outline,
        ),
        title: Text(topic.title(ru)),
        subtitle: Text(
          topic.explanation(ru),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => showLearningTopicSheet(context, topic),
      ),
    );
  }
}
