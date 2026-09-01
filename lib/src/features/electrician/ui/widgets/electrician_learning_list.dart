import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/learning_progress.dart';
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
    final passed = ref.watch(learningProgressProvider);
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: topics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final done = passed.contains(topic.id);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(
                          done
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: done
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text(topic.title(ru)),
                        subtitle: Text(
                          topic.explanation(ru),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('${topic.quiz.length}'),
                        onTap: () => showLearningTopicSheet(context, topic),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
