import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';

/// Тема целиком: объяснение, пример и тест.
///
/// Тема засчитывается только когда все вопросы отвечены верно. Ответ на
/// вопрос сразу показывает объяснение — и когда угадал, и когда ошибся:
/// иначе тест проверяет память, а не понимание.
Future<void> showLearningTopicSheet(
  BuildContext context,
  LearningTopic topic,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TopicSheet(topic: topic),
    );

class _TopicSheet extends ConsumerStatefulWidget {
  const _TopicSheet({required this.topic});

  final LearningTopic topic;

  @override
  ConsumerState<_TopicSheet> createState() => _TopicSheetState();
}

class _TopicSheetState extends ConsumerState<_TopicSheet> {
  final _answers = <int, int>{};

  bool get _allCorrect =>
      _answers.length == widget.topic.quiz.length &&
      _answers.entries.every(
        (entry) => widget.topic.quiz[entry.key].correctIndex == entry.value,
      );

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.topic.title(ru),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(widget.topic.explanation(ru)),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.example,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(widget.topic.example(ru)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < widget.topic.quiz.length; index++)
                _Question(
                  question: widget.topic.quiz[index],
                  chosen: _answers[index],
                  onChosen: (value) => setState(() => _answers[index] = value),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _allCorrect
                    ? () async {
                        await ref
                            .read(toolDataControllerProvider.notifier)
                            .markTopicPassed(widget.topic.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: Text(strings.markLearned),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.chosen,
    required this.onChosen,
  });

  final QuizQuestion question;
  final int? chosen;
  final ValueChanged<int> onChosen;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    final theme = Theme.of(context);
    final options = question.options(ru);
    final correct = chosen == question.correctIndex;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.question(ru), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (var index = 0; index < options.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  chosen == index
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: chosen == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(options[index]),
                onTap: () => onChosen(index),
              ),
            if (chosen != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: correct
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      correct ? strings.answerRight : strings.answerWrong,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(question.explanation(ru)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
